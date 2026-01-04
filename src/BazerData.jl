module BazerData

# --------------------------------------------------------------------------------------------------
import ColorSchemes: get, colorschemes
import Crayons: @crayon_str
import Dates: Date
import DataFrames: AbstractDataFrame, ByRow, DataFrame, groupby, combine, nrow,  Not,  nonunique, proprow, 
    rename, rename!, select, select!, transform, transform!, unstack
import Dates: format, now, DatePeriod, Dates, Dates.AbstractTime, ISODateTimeFormat
import Interpolations: Linear, Constant, Previous, Next, BSpline, interpolate
import Missings: disallowmissing
import PrettyTables: Crayon, ft_printf, get, Highlighter, pretty_table
import Random: seed!
import StatsBase: quantile, UnitWeights, Weights
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# Import functions
include("PanelData.jl")
include("TimeShift.jl")
include("StataUtils.jl")
include("Winsorize.jl")
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# List of exported functions
export panel_fill, panel_fill!
export tlead, tlag, tshift
export tabulate 
export xtile
export winsorize
# --------------------------------------------------------------------------------------------------

end
