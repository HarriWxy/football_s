"""Compatibility alias for the bundled five-a-side scenario."""

from importlib import import_module


def build_scenario(builder):
    """Build the standard GFootball 5 vs 5 scenario under the MALib name."""

    scenario = import_module(".5_vs_5", package=__package__)
    scenario.build_scenario(builder)
