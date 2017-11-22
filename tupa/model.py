from collections import OrderedDict
from enum import Enum

from .action import Actions
from .classifiers.classifier import Classifier
from .config import Config, SPARSE, MLP, BIRNN, NOOP
from .features.enumerator import FeatureEnumerator
from .features.feature_params import FeatureParameters
from .model_util import UnknownDict, AutoIncrementDict


class ParameterDefinition(object):
    def __init__(self, name, **param_attr_to_config_attr):
        self.name = name
        self.param_attr_to_config_attr = param_attr_to_config_attr

    @property
    def enabled(self):
        return bool(getattr(Config().args, self.param_attr_to_config_attr["dim"]))

    def create_from_config(self):
        args = Config().args
        return FeatureParameters(self.name, **{k: getattr(args, v) if hasattr(args, v) else v
                                               for k, v in self.param_attr_to_config_attr.items()})

    def load_to_config(self, params):
        param = params.get(self.name)
        if param is not None:
            args = Config().args
            Config().update({v: getattr(param, k) for k, v in self.param_attr_to_config_attr.items()
                             if hasattr(args, v)})


NODE_LABEL_KEY = "n"

PARAM_DEFS = (
    ParameterDefinition(NODE_LABEL_KEY, dim="node_label_dim", size="max_node_labels", min_count="min_node_label_count",
                        dropout="node_label_dropout"),
    ParameterDefinition("c", dim="node_category_dim", size="max_node_categories"),
    ParameterDefinition("W", dim="word_dim_external", size="max_words_external", dropout="word_dropout_external",
                        updated="update_word_vectors", filename="word_vectors",  copy_from="w"),
    ParameterDefinition("w", dim="word_dim",          size="max_words",          dropout="word_dropout"),
    ParameterDefinition("t", dim="tag_dim",           size="max_tags",           dropout="tag_dropout"),
    ParameterDefinition("d", dim="dep_dim",           size="max_deps",           dropout="dep_dropout"),
    ParameterDefinition("e", dim="edge_label_dim",    size="max_edge_labels"),
    ParameterDefinition("p", dim="punct_dim",         size="max_puncts"),
    ParameterDefinition("A", dim="action_dim",        size="max_action_types"),
    ParameterDefinition("T", dim="ner_dim",           size="max_ner_types"),
)


class ClassifierProperty(Enum):
    update_only_on_error = 1
    require_init_features = 2
    trainable_after_saving = 3


CLASSIFIER_PROPERTIES = {
    SPARSE: (ClassifierProperty.update_only_on_error,),
    MLP: (ClassifierProperty.trainable_after_saving,),
    BIRNN: (ClassifierProperty.trainable_after_saving, ClassifierProperty.require_init_features),
    NOOP: (),
}


class Model(object):
    def __init__(self, model_type, filename, *args, **kwargs):
        self.args = Config().args
        self.model_type = model_type or SPARSE
        self.filename = filename
        self.feature_extractor = self.classifier = None
        self.feature_params = OrderedDict()
        if args or kwargs:
            self.restore(*args, **kwargs)

    def init_model(self, init_params=True):
        labels = self.classifier.labels if self.classifier else {}
        feature_params_required = self.model_type in (MLP, BIRNN)
        if init_params:  # Actually use the config state to initialize the features and hyperparameters, otherwise empty
            for param_def in PARAM_DEFS:
                param = self.feature_params.get(param_def.name)
                if param:
                    param.enabled = param_def.enabled
                elif feature_params_required and param_def.enabled:
                    self.feature_params[param_def.name] = param_def.create_from_config()
            if Config().format not in labels:
                labels[Config().format] = self.init_actions()  # Uses config to determine actions
            if self.args.node_labels and NODE_LABEL_KEY not in labels:
                labels[NODE_LABEL_KEY] = self.init_node_labels().data  # Uses self.feature_params
        if self.classifier:  # Already initialized
            pass
        elif self.model_type == SPARSE:
            from .features.sparse_features import SparseFeatureExtractor
            from .classifiers.linear.sparse_perceptron import SparsePerceptron
            self.feature_extractor = SparseFeatureExtractor()
            self.classifier = SparsePerceptron(self.filename, labels)
        elif self.model_type == NOOP:
            from .features.empty_features import EmptyFeatureExtractor
            from .classifiers.noop import NoOp
            self.feature_extractor = EmptyFeatureExtractor()
            self.classifier = NoOp(self.filename, labels)
        elif feature_params_required:
            from .features.dense_features import DenseFeatureExtractor
            from .classifiers.nn.neural_network import NeuralNetwork
            self.feature_extractor = FeatureEnumerator(DenseFeatureExtractor(), self.feature_params,
                                                       indexed=self.model_type == BIRNN)
            self.classifier = NeuralNetwork(self.model_type, self.filename, labels)
        else:
            raise ValueError("Invalid model type: '%s'" % self.model_type)
        self._update_input_params()

    def init_actions(self):
        return Actions(size=self.args.max_action_labels)

    def init_node_labels(self):
        node_labels = self.feature_params.get(NODE_LABEL_KEY)
        if node_labels is None:
            node_labels = next(p for p in PARAM_DEFS if p.name == NODE_LABEL_KEY).create_from_config()
            self.feature_params[NODE_LABEL_KEY] = node_labels
        FeatureEnumerator.init_data(node_labels)
        return node_labels

    @property
    def actions(self):
        return self.classifier.labels[Config().format]

    @property
    def labels(self):
        return self.classifier.labels[NODE_LABEL_KEY]

    def init_features(self, state, axes, train):
        self.init_model()
        self.classifier.init_features(self.feature_extractor.init_features(state), axes, train)

    def finalize(self, finished_epoch):
        """
        Copy model, finalizing features (new values will not be added during subsequent use) and classifier (update it)
        :param finished_epoch: whether this is the end of an epoch (or just intermediate checkpoint), for bookkeeping
        :return: a copy of this model with a new feature extractor and classifier (actually classifier may be the same)
        """
        self.init_model()
        return Model(None, None, model=self,
                     feature_extractor=self.feature_extractor.finalize(),
                     classifier=self.classifier.finalize(finished_epoch=finished_epoch))

    def save(self):
        """
        Save feature and classifier parameters to files
        """
        if self.filename is not None:
            self.init_model()
            try:
                self.feature_extractor.save(self.filename)
                node_labels = self.feature_extractor.params.get(NODE_LABEL_KEY)
                self.classifier.save(skip_labels=(NODE_LABEL_KEY,) if node_labels and node_labels.size else ())
            except Exception as e:
                raise IOError("Failed saving model to '%s'" % self.filename) from e

    def load(self, finalized=True):
        """
        Load the feature and classifier parameters from files
        :param finalized: whether the loaded model should be finalized, or allow feature values to be added subsequently
        """
        if self.filename is not None:
            try:
                self.model_type = Classifier.get_model_type(self.filename)
                self.init_model(init_params=False)
                self.feature_extractor.load(self.filename)
                if not finalized:
                    self.feature_extractor.restore()
                self._update_input_params()  # Must be before classifier.load() because it uses them to init the model
                self.classifier.load()
                self.load_labels(finalized)
                for param in PARAM_DEFS:
                    param.load_to_config(self.feature_extractor.params)
            except FileNotFoundError:
                self.feature_extractor = self.classifier = None
                raise
            except Exception as e:
                raise IOError("Failed loading model from '%s'" % self.filename) from e

    def restore(self, model, feature_extractor=None, classifier=None):
        """
        Set all attributes to a reference to existing model, except labels, which will be copied.
        Restored model is not finalized: new feature values will be added during subsequent training
        :param model: Model to restore
        :param feature_extractor: optional FeatureExtractor to restore instead of model's
        :param classifier: optional Classifier to restore instead of model's
        """
        self.model_type = model.model_type
        self.filename = model.filename
        self.feature_extractor = feature_extractor or model.feature_extractor
        self.classifier = classifier or model.classifier
        self._update_input_params()
        self.classifier.labels_t = {a: l.save() for a, l in self.classifier.labels.items()}
        self.load_labels()

    def load_labels(self, finalized=True):
        """
        Copy classifier's labels to create new Actions/Labels objects
        Restoring from a model that was just loaded from file, or called by restore()
        """
        for axis, all_size in self.classifier.labels_t.items():  # all_size is a pair of (label list, size limit)
            if axis == NODE_LABEL_KEY:  # These are node labels rather than action labels
                node_labels = self.feature_extractor.params.get(NODE_LABEL_KEY)
                if node_labels and node_labels.size:  # Also used for features, so share the dict
                    del all_size
                    labels = node_labels.data
                else:  # Not used as a feature, just get labels
                    labels = UnknownDict() if finalized else AutoIncrementDict()
                    labels.load(all_size)
            else:  # Action labels for format determined by axis
                labels = Actions(*all_size)
            self.classifier.labels[axis] = labels

    def get_classifier_properties(self):
        return CLASSIFIER_PROPERTIES[self.model_type]

    def _update_input_params(self):
        self.feature_params = self.classifier.input_params = self.feature_extractor.params

    def get_all_params(self):
        d = OrderedDict()
        for name, indexed in (("features", False), ("indexed_features", True)):
            features = self.feature_extractor.get_all_features(indexed)
            if features:
                d[name] = features
        d.update(("input_" + s, p.data.all) for s, p in self.feature_extractor.params.items() if p.data)
        d.update(self.classifier.get_all_params())
        return d
