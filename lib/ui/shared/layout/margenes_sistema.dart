import 'package:flutter/widgets.dart';

/// Márgenes para que nada quede debajo de las barras del sistema.
///
/// La app se dibuja de borde a borde (Android 15+ lo exige), así que la
/// barra de navegación de 3 botones o de gestos queda ENCIMA del contenido.
/// Las listas, formularios y botones inferiores deben sumar este margen.
/// Ojo: dentro de un `showModalBottomSheet` el margen inferior sigue en el
/// `MediaQuery`, así que también hay que sumarlo ahí.
abstract final class MargenesSistema {
  /// Alto de la barra del sistema inferior + [extra].
  /// Usa `paddingOf` (no `viewPaddingOf`) para que, con el teclado abierto,
  /// no se sume dos veces.
  static double inferior(BuildContext context, {double extra = 16}) =>
      MediaQuery.paddingOf(context).bottom + extra;

  /// Relleno típico de una lista con scroll.
  static EdgeInsets lista(
    BuildContext context, {
    double horizontal = 0,
    double arriba = 4,
    double extraInferior = 24,
  }) =>
      EdgeInsets.fromLTRB(
        horizontal,
        arriba,
        horizontal,
        inferior(context, extra: extraInferior),
      );

  /// Relleno típico de un formulario.
  static EdgeInsets formulario(BuildContext context, {double lados = 16}) =>
      EdgeInsets.fromLTRB(
          lados, lados, lados, inferior(context, extra: lados + 8));
}
