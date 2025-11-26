# Resumen de errores y soluciones

Este documento recopila los errores más frecuentes que ya se corrigieron o se manejan en el código del EA, junto con la forma de evitarlos o recuperarse.

## Inicialización del EA
- **Parámetros inválidos**: los periodos de Donchian o ATR y el spread máximo deben ser positivos; de lo contrario, `ValidateParameters()` aborta la carga del experto. Ajustar los inputs antes de compilar/ejecutar.
- **Creación de indicadores**: si el manejador de ATR no se crea (`iATR` devuelve `INVALID_HANDLE`) o si `CopyBuffer` falla, el init falla. Verificar que el símbolo y timeframe estén disponibles y que haya histórico suficiente.

## Cálculo de indicadores
- **Histórico insuficiente**: los cálculos Donchian exigen al menos `Inp_DonchianEntradaPeriod` y `Inp_DonchianSalidaPeriod` velas cerradas. Si `CopyHigh/CopyLow` devuelve menos barras, el tick se descarta. Esperar a que el histórico se complete o reducir los periodos.

## Generación de señales
- **Datos de precio inaccesibles**: la señal se descarta si fallan `SymbolInfoDouble` (punto o ask) o `CopyClose`. Revisar la conexión de datos del símbolo.

## Gestión de riesgo
- **Lectura del spread**: si no se puede obtener `SYMBOL_SPREAD` o el valor supera `Inp_SpreadMaximo`, no se sigue operando. Confirmar que el bróker provea datos y ajustar el límite si procede.
- **Historial del día**: si `HistorySelect` falla, se continúa pero se avisa; la lógica de pérdida diaria compara el beneficio del día con `Inp_MaxDailyLossPct`.
- **Datos de trading inválidos**: se aborta el cálculo de lote cuando faltan `SYMBOL_VOLUME_MIN/MAX/STEP`, tick value/size, o cuando el stop es inválido (distancia ≤ 0 o puntos ≤ 0). Revisar los límites de símbolo y que el stop esté por debajo del precio de entrada.
- **Normalización de stop-loss**: si faltan `SYMBOL_POINT` o `SYMBOL_DIGITS`, se usan valores por defecto y se aplican `SYMBOL_TRADE_STOPS_LEVEL` para evitar stops demasiado cercanos.

## Operativa
- **Apertura y cierre de órdenes**: fallar al leer el ask (`SYMBOL_ASK`) o un error de `CTrade::Buy/PositionClose/PositionModify` impide abrir, cerrar o actualizar stops. Revisar el estado de trading del símbolo, margen y deslizamiento configurado.

## Salidas y visualización
- **Lecturas para salida**: la gestión de salida necesita `SYMBOL_POINT`, acceso a la posición actual y `CopyClose`; si alguno falla, se registra y se omite el ajuste.
- **Actualización del panel**: el panel solo se refresca cuando hay datos de indicadores; asegúrate de que los cálculos previos hayan sido exitosos.
