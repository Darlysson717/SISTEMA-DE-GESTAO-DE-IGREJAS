import 'package:flutter/material.dart';

/// Observador global de rotas para navegação no aplicativo.
///
/// Instância singleton do [RouteObserver] usada para rastrear
/// transições de páginas em todo o app. Pode ser utilizado para:
/// - Analytics de navegação
/// - Gerenciamento de estado baseado em rota ativa
/// - Animações e transições personalizadas
///
/// Configurado no [NavigatorObserver] do [MaterialApp].
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();