## MATLAB Files for Sang System Analysis

#### `bo_sang_bif_IC.m`
- **Purpose**: Bifurcation analysis with respect to initial conditions
- **Key Features**:
  - Compares hidden attractor (c < 0) vs self-excited attractor (c > 0) behavior
  - Generates phase portraits and bifurcation diagrams
  - Uses Heun's method for numerical integration
  - Analyzes sensitivity to initial condition value `s`: $(x_0, y_0, z_0) = (0, s, 0)$

#### `sang_bifurcation_analysis.m`
- **Purpose**: Comprehensive bifurcation analysis of the Sang system
- **Key Features**:
  - Studies parameter `μ` as bifurcation parameter
  - Uses custom `bifurcation_1d_analyzer` class from `supplementary` folder. The latest version and examples for this class may be found at [Bifurcation 1D Analysis - MATLAB Central File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/179659-bifurcation-1d-analysis).
  - Compares behavior for different `c` values (positive/negative)
  - Includes phase portrait visualization.

#### `sang_sim_fimath.m`
- **Purpose**: Fixed-point implementation using MATLAB's embedded type `fimath`. Works rather slow.
- **Key Features**:
  - Emulates hardware-friendly fixed-point arithmetic
  - Configurable word length and fraction length

#### `sang_sim_FXP_emulation.m`
- **Purpose**: Manual fixed-point emulation without `fimath`. Works as fast as common MATLAB codes. Fraction length influence arithmetic accuracy.
- **Key Features**:
  - Implements fixed-point arithmetic using scaling factors and manual rounding
  - Word length limitation is currently not considered

### `verilog_output_visualization.m`
- **Purpose**: Visualization of Verilog simulation results
- **Key Features**:
  - Reads output from Verilog cos_chaos simulation
  - Plots phase portraits and time series
  - Compares MATLAB and Verilog results
  - Uses LaTeX formatting for professional plots

