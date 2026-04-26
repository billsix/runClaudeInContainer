# Copyright (c) 2025-2026 William Emerison Six
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.


import math
import typing
import warnings

import sympy
from IPython.display import Math, display

from geometricalgebra.multivector import (
    InvertibleFunction,
    MultiVector,
    MultiVectorFn,
    a_1,
    compose,
    compose_intermediate_fns,
    e_1,
    e_2,
    e_3,
    e_4,
    inverse,
    rotate,
    scale_non_uniform_2d,
    sym_vec2_1,
    sym_vec2_2,
    sym_vec3_1,
    sym_vec3_2,
    translate,
)
from geometricalgebra.nbplotutils import (
    create_basis,
    create_graphs,
    create_unit_circle,
    create_x_and_y,
    draw_isoceles_triangle,
    draw_right_triangle,
    draw_second_right_triangle,
    show_mult,
)

# turn warnings into exceptions
warnings.filterwarnings("error", category=RuntimeWarning)


# faoeuaoue
i: MultiVector = e_1 * e_2
i  # pyright: ignore[reportUnusedExpression]


i * i  # pyright: ignore[reportUnusedExpression]


2 * e_1 + 3 * e_2 + 5 * e_1  # pyright: ignore[reportUnusedExpression]


sym_vec2_1  # pyright: ignore[reportUnusedExpression]


sym_vec2_2  # pyright: ignore[reportUnusedExpression]


Math("$($" + sym_vec2_1._repr_latex_() + "$)*($" + sym_vec2_2._repr_latex_() + "$)$")


sym_vec2_1 * sym_vec2_2  # pyright: ignore[reportUnusedExpression]


sym_vec2_1.dot(sym_vec2_2)


sym_vec2_1.wedge(sym_vec2_2)


e1e2plane: MultiVectorFn = MultiVector.project(onto=e_1 * e_2)
e1e2plane(sym_vec3_1) ^ e1e2plane(sym_vec3_2)  # pyright: ignore[reportUnusedExpression]


e2e3plane: MultiVectorFn = MultiVector.project(onto=e_2 * e_3)
e2e3plane(sym_vec3_1) ^ e2e3plane(sym_vec3_2)  # pyright: ignore[reportUnusedExpression]


e1e3plane: MultiVectorFn = MultiVector.project(onto=e_1 * e_3)
e1e3plane(sym_vec3_1) ^ e1e3plane(sym_vec3_2)  # pyright: ignore[reportUnusedExpression]


# ordering of the plane doesn't matter
e3e1plane: MultiVectorFn = MultiVector.project(onto=e_3 * e_1)
e3e1plane(sym_vec3_1) ^ e1e3plane(sym_vec3_2)  # pyright: ignore[reportUnusedExpression]


sym_vec3_1 * sym_vec3_2  # pyright: ignore[reportUnusedExpression]


def gram_fe_to_mol_fe(gram_fe: float) -> MultiVector:
    # let gram_fe be e_1
    # let mol_fe be e_2
    unit_gram_fe: MultiVector = e_1
    unit_mol_fe: MultiVector = e_2

    ratio: MultiVector = (55.85 * unit_gram_fe).inverse() * (1 * unit_mol_fe)
    return gram_fe * unit_gram_fe * ratio


gram_fe_to_mol_fe(gram_fe=95.8)


for x in MultiVector.bases(1):
    display(Math(x._repr_latex_()))


MultiVector.symbolic_multivector(grade=1, prefix="a")


for x in MultiVector.bases(2):
    display(Math(x._repr_latex_()))


MultiVector.symbolic_multivector(grade=2, prefix="b")


MultiVector.symbolic_multivector(
    grade=2, prefix="b"
) * MultiVector.symbolic_multivector(grade=2, prefix="d")  # pyright: ignore[reportUnusedExpression]


MultiVector.symbolic_multivector(grade=2, prefix="c").r_vector_part(0)


MultiVector.symbolic_multivector(grade=2, prefix="c").r_vector_part(1)


MultiVector.symbolic_multivector(grade=2, prefix="c").r_vector_part(2)


for x in MultiVector.bases(3):
    display(Math(x._repr_latex_()))


MultiVector.symbolic_multivector(grade=3, prefix="c")


MultiVector.symbolic_multivector(grade=3, prefix="c").r_vector_part(0)


MultiVector.symbolic_multivector(grade=3, prefix="c").r_vector_part(1)


MultiVector.symbolic_multivector(grade=3, prefix="c").r_vector_part(2)


MultiVector.symbolic_multivector(grade=3, prefix="c").r_vector_part(3)


a_1 * e_1 * e_2 * e_4  # pyright: ignore[reportUnusedExpression]


asdf = MultiVector.symbolic_multivector(grade=3, prefix="e").r_vector_part(1)
asdf2 = MultiVector.symbolic_multivector(grade=3, prefix="f").r_vector_part(1)
asdf3 = asdf ^ asdf2
asdf3  # pyright: ignore[reportUnusedExpression]


asdf3 * asdf3


asdf3.dual(3)


asdf3.dot(asdf3.dual(3))


show_mult(asdf3, asdf3.dual(3))


asdf3 * (asdf3.dual(3))  # pyright: ignore[reportUnusedExpression]


show_mult(sym_vec2_1, sym_vec2_2)


show_mult(sym_vec3_1, sym_vec3_2)


show_mult(
    MultiVector.symbolic_multivector(grade=8, prefix="a").r_vector_part(1),
    MultiVector.symbolic_multivector(grade=9, prefix="b").r_vector_part(1),
)


T: typing.Callable[[MultiVector], MultiVectorFn] = translate
S: typing.Callable[[float, float], MultiVectorFn] = scale_non_uniform_2d
R: typing.Callable[[float], InvertibleFunction] = rotate


T(5 * e_1)


S(5, 6)


inverse(T(5 * e_1))


T(5 * e_1 + 6 * e_2)


T(5 * e_1 + 6 * e_2 + 7 * e_3)


inverse(T(5 * e_1 + 6 * e_2 + 7 * e_3))


R(sympy.pi / 2)


compose([R(sympy.pi / 2), T(5 * e_1 + 6 * e_2)])


inverse(compose([R(sympy.pi / 2), T(5 * e_1 + 6 * e_2)]))


fn = R(math.radians(53.130102))
with create_graphs(graph_bounds=(5, 5)) as axes:
    create_basis(fn=fn)
    create_x_and_y(fn=fn)
    create_unit_circle(fn=fn)
    axes.set_title(fn._repr_latex_())


fn = R(math.radians(53.130102))
with create_graphs(graph_bounds=(5, 5)) as axes:
    create_basis(fn=R(0.0))
    create_x_and_y(fn=R(0.0))
    create_basis(
        fn=fn,
        xcolor=(0, 1, 0),
        ycolor=(1, 1, 0),
    )
    create_x_and_y(
        fn=fn,
        xcolor=(0, 1, 0),
        ycolor=(1, 1, 0),
    )
    create_unit_circle(fn=fn)
    axes.set_title(fn._repr_latex_())


fn = R(math.radians(53.130102))
with create_graphs(graph_bounds=(5, 5)) as axes:
    create_basis(fn=R(0.0))
    create_x_and_y(fn=R(0.0))
    create_basis(
        fn=fn,
        xcolor=(0, 1, 0),
        ycolor=(1, 1, 0),
    )
    create_x_and_y(
        fn=fn,
        xcolor=(0, 1, 0),
        ycolor=(1, 1, 0),
    )
    create_unit_circle(fn=fn)
    draw_right_triangle()
    draw_second_right_triangle()
    axes.set_title(fn._repr_latex_())


fn = compose(
    [
        R(sympy.pi / 4),
        T(2 * e_1),
    ]
)
with create_graphs() as axes:
    create_basis(
        fn=fn,
    )
    create_x_and_y(fn=fn)
    create_unit_circle(fn=fn)
    axes.set_title(fn._repr_latex_())


for f in compose_intermediate_fns([R(sympy.pi / 4), T(2 * e_1)]):
    # TODO - figure out if I can render the latex as part of one markdown command,
    # if I were to uncomment out this line and other markdown lines,
    # the build of HTML would fail

    with create_graphs() as axes:
        create_basis(fn=f)
        create_x_and_y(fn=f)
        create_x_and_y()
        draw_isoceles_triangle(fn=f)
        create_unit_circle(fn=f)
        create_unit_circle()
        axes.set_title(f._repr_latex_())


for f in compose_intermediate_fns(
    [
        R(sympy.pi / 4),
        T(2 * e_1),
    ],
    relative_basis=True,
):
    with create_graphs() as axes:
        create_basis(fn=f)
        create_x_and_y(fn=f)
        draw_isoceles_triangle(fn=f)
        create_unit_circle(fn=f)
        axes.set_title(f._repr_latex_())
