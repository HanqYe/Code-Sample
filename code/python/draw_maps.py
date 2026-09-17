"""
Figure 7: first-tier admission rates and influencer audience density by province.

Province boundaries come from the public DataV boundary service and are cached
in data/china_provinces.json. Province-level values come from prov_density.csv,
which 08_mechanisms.do writes.
"""

import os

import geopandas as gpd
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib import rcParams
from matplotlib.patches import Rectangle

BASE = os.environ.get("GK_BASE", r"E:\replication")
OUT = os.path.join(BASE, "output", "figures")
GEO = os.path.join(BASE, "data", "china_provinces.json")
DAT = os.path.join(BASE, "data", "prov_density.csv")

rcParams["font.family"] = "DejaVu Sans"

# The four provinces known collectively as the four of mountains and rivers
SHANHE = ["\u5c71\u4e1c", "\u5c71\u897f", "\u6cb3\u5357", "\u6cb3\u5317"]
BOXCOL = "#E67E22"
PAD = 0.15

gdf = gpd.read_file(GEO)
dat = pd.read_csv(DAT)

# The GeoJSON carries full names such as Hebei Province, the data carries the
# short form, so match on prefix
short = list(dat["province"])


def match(full):
    for s in short:
        if str(full).startswith(s):
            return s
    return None


# Thin the boundaries to 0.02 degrees. No visible difference at print width and
# it more than halves the size of the PDF, which matters for compile time.
gdf["geometry"] = gdf.geometry.simplify(0.02, preserve_topology=True)
gdf["province"] = gdf["name"].map(match)
gdf = gdf.merge(dat, on="province", how="left")
print("matched:", gdf["rate"].notna().sum(), "of", len(dat))

minx, miny, maxx, maxy = gdf[gdf["province"].isin(SHANHE)].total_bounds

PANELS = [
    ("rate", "Greens", "(a)  Share admitted above the first-tier line", "{:.2f}"),
    ("density", "Blues", "(b)  Influencer audience density", "{:.1f}"),
]


def draw(ax, col, cmap, title, fmt):
    gdf.plot(column=col, cmap=cmap, ax=ax, linewidth=0.3,
             edgecolor="#7a7a7a", scheme="quantiles", k=5,
             missing_kwds={"color": "#f4f4f4", "edgecolor": "#cccccc",
                           "linewidth": 0.25},
             legend=True)

    # Drop the NaN entry geopandas adds and relabel the ranges as a - b
    leg = ax.get_legend()
    handles, labels = [], []
    for h, t in zip(leg.legend_handles, leg.get_texts()):
        parts = t.get_text().split(",")
        if len(parts) != 2:
            continue
        lo, hi = (float(v) for v in parts)
        handles.append(h)
        labels.append(f"{fmt.format(lo)} \u2013 {fmt.format(hi)}")
    leg.remove()
    ax.legend(handles, labels, loc="lower left", fontsize=8.5,
              frameon=False, handlelength=1.1, handleheight=1.1,
              labelspacing=0.35, borderpad=0.2,
              bbox_to_anchor=(0.02, 0.03))

    ax.add_patch(Rectangle((minx - PAD, miny - PAD),
                           (maxx - minx) + 2 * PAD, (maxy - miny) + 2 * PAD,
                           fill=False, edgecolor=BOXCOL,
                           linewidth=1.5, linestyle=(0, (5, 3)), zorder=5))
    ax.set_title(title, fontsize=11.5, pad=8, loc="left", x=0.04)
    ax.set_xlim(72, 137)
    ax.set_ylim(15, 55)
    ax.axis("off")


fig, axes = plt.subplots(1, 2, figsize=(13.2, 6.2))
for ax, (col, cmap, title, fmt) in zip(axes, PANELS):
    draw(ax, col, cmap, title, fmt)
    ax.annotate("Hebei, Shanxi,\nShandong, Henan",
                xy=(maxx + PAD, miny + 1.0), xytext=(130.5, 26),
                fontsize=8.5, color=BOXCOL, ha="center", va="center",
                arrowprops=dict(arrowstyle="-", color=BOXCOL, linewidth=0.9,
                                connectionstyle="arc3,rad=0.15"))

fig.subplots_adjust(wspace=0.02)
fig.savefig(os.path.join(OUT, "fig_maps.pdf"), bbox_inches="tight")
fig.savefig(os.path.join(OUT, "fig_maps.png"), dpi=300, bbox_inches="tight")
print("saved fig_maps.pdf and fig_maps.png")
