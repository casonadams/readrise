enum MatterState { solid, liquid, gas }

/// Water at sea-level pressure: solid below 0 C, gas from 100 C up.
/// At exactly 0 C real ice and water coexist; the model keeps it liquid.
MatterState waterStateAt(double celsius) => celsius < 0
    ? MatterState.solid
    : celsius < 100
    ? MatterState.liquid
    : MatterState.gas;

/// Particle motion on a 0..1 scale for the lab's -20..120 C range.
double energyAt(double celsius) => ((celsius + 20) / 140).clamp(0.0, 1.0);
