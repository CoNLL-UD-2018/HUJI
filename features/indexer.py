from features.feature_extractor_wrapper import FeatureExtractorWrapper

INDEXED_FEATURES = "W", "w", "t"  # external word embeddings, learned word embeddings, POS tags


class FeatureIndexer(FeatureExtractorWrapper):
    """
    Wrapper for FeatureEnumerator to replace non-numeric feature values with indices.
    To be used with LSTMNeuralNetwork classifier.
    """
    def __init__(self, feature_extractor, params=None):
        super(FeatureIndexer, self).__init__(feature_extractor, feature_extractor.params if params is None else params)
        if params is None:
            for suffix in INDEXED_FEATURES:
                param = self.params.get(suffix)
                if param is not None:
                    param.indexed = True
        else:
            feature_extractor.params = params
        self.feature_extractor.collapse_features(INDEXED_FEATURES)
