"""Testing code for the amr package, unit-testing only."""

import unittest

from ucca.convert import split2sentences

from scheme.conversion.amr import from_amr, to_amr
from scheme.evaluation.amr import evaluate


class ConversionTests(unittest.TestCase):
    """Tests conversion module correctness and API."""

    def test_convert(self):
        """Test that converting an AMR to UCCA and back retains perfect Smatch F1"""
        for passage, ref, amr_id in read_test_amr():
            converted = to_amr(passage, metadata=False)[0]
            scores = evaluate(converted, ref, amr_id)
            self.assertAlmostEqual(scores.f1, 1, msg=converted)

    def test_split(self):
        """Test that splitting a single-sentence AMR converted to UCCA returns the same AMR"""
        for passage, ref, amr_id in read_test_amr():
            sentences = split2sentences(passage)
            self.assertEqual(len(sentences), 1, "Should be one sentence: %s" % passage)
            sentence = sentences[0]
            converted = to_amr(sentence, metadata=False)[0]
            scores = evaluate(converted, ref, amr_id)
            self.assertAlmostEqual(scores.f1, 1, msg=converted)


class UtilTests(unittest.TestCase):
    """Tests the amrutil module functions and classes."""

    def test_evaluate(self):
        """Test that comparing an AMR against itself returns perfect Smatch F1"""
        for _, ref, amr_id in read_test_amr():
            scores = evaluate(ref, ref, amr_id)
            self.assertAlmostEqual(scores.f1, 1)


def read_test_amr():
    with open("test_files/LDC2014T12.txt") as f:
        return list(from_amr(f, return_amr=True))
