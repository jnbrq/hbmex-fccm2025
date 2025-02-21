from drawio import *
from typing import *


def trapezoid(
        n: int,
        baseName: str,
        label: str = "",
        reflect: bool = False,
        fontSize: float = 12.5
) -> Shape:
    shape = Shape(
        f"{baseName}_{n}",
        Size(20, n * 20),
        "variable"
    )

    path = Path()

    if not reflect:
        path.move(Point(0, 0))
        path.lineTo(Point(0, n * 20))
        path.lineTo(Point(20, n * 20 - 10))
        path.lineTo(Point(20, 10))
        path.close()

        shape.foreground.append(path)
        shape.foreground.append(FillStroke())

        shape.foreground.append(FontSize(fontSize))
        shape.foreground.append(FontStyle(1))
        shape.foreground.append(
            Label(
                label.format(n),
                10, n * 20 / 2,
                "center", "middle",
                rotation=90
            )
        )

        for i in range(n):
            shape.connections.append(Point(0, 10 + (i * 20)))
        shape.connections.append(Point(20, n * 20 / 2))
        shape.connections.append(Point(10, 5))
        shape.connections.append(Point(10, n * 20 - 5))

    else:
        path.move(Point(0, 10))
        path.lineTo(Point(0, n * 20 - 10))
        path.lineTo(Point(20, n * 20))
        path.lineTo(Point(20, 0))
        path.close()

        shape.foreground.append(path)
        shape.foreground.append(FillStroke())

        shape.foreground.append(FontSize(fontSize))
        shape.foreground.append(FontStyle(1))
        shape.foreground.append(
            Label(
                label.format(n),
                10, n * 20 / 2,
                "center", "middle",
                rotation=90
            )
        )

        for i in range(n):
            shape.connections.append(Point(20, 10 + (i * 20)))
        shape.connections.append(Point(0, n * 20 / 2))
        shape.connections.append(Point(10, 5))
        shape.connections.append(Point(10, n * 20 - 5))

    return shape


if __name__ == "__main__":
    shapeLibrary = ShapeLibrary()

    def trapezoids(baseName: str, label: str, ns: List[int], fontSize: float, reflect: bool) -> None:
        for n in ns:
            mux = trapezoid(n, baseName, label, reflect=reflect, fontSize=fontSize)
            shapeLibrary.shapes.append(mux)
    
    trapezoids("mux", "Mux", [2], 8, False)
    trapezoids("mux", "Mux [{}]", [3], 8.5, False)
    trapezoids("mux", "Mux [{}]", [4, 5, 6, 7, 8], 12.5, False)
    
    trapezoids("arbiter", "Arb", [2], 8, False)
    trapezoids("arbiter", "Arb [{}]", [3], 8.5, False)
    trapezoids("arbiter", "Arbiter [{}]", [4, 5, 6, 7, 8], 12.5, False)
    
    trapezoids("demux", "Demux", [2], 8, True)
    trapezoids("demux", "Demux [{}]", [3], 8.5, True)
    trapezoids("demux", "Demux [{}]", [4, 5, 6, 7, 8], 12.5, True)
    
    trapezoids("distributor", "Dist", [2], 8, True)
    trapezoids("distributor", "Dist [{}]", [3], 8.5, True)
    trapezoids("distributor", "Dist [{}]", [4], 12.5, True)
    trapezoids("distributor", "Distributor [{}]", [5, 6, 7, 8], 12.5, True)

    trapezoids("basic", "", [2, 3, 4, 5, 6, 7, 8], 8, False)

    with open("elastic_shapes.xml", "w") as f:
        f.write(shapeLibrary.to_str())
