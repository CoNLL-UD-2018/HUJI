from scheme.constraints import Constraints

TOP_LEVEL = ("root",)


class ConlluConstraints(Constraints):
    def __init__(self, args):
        super(ConlluConstraints, self).__init__(args, top_level_allowed=TOP_LEVEL, top_level_only=TOP_LEVEL)
