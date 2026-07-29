// Web-only: usa dart:js para acessar a Notification API do navegador
// Este arquivo só é compilado para web
import 'dart:js' as js;

/// Exibe notificação via Web Notification API nativa do navegador
void exibirNotificacaoWeb(
  String titulo,
  String corpo,
  Map<String, dynamic>? dados,
  void Function(Map<String, dynamic>?) aoClicar,
) {
  try {
    final notificationApi = js.context['Notification'];
    if (notificationApi == null) return;

    final permission = notificationApi['permission'];
    if (permission == 'granted') {
      final options = js.JsObject.jsify({
        'body': corpo,
        'icon': 'icons/Icon-192.png',
        'tag': 'desiadet-notification',
        'requireInteraction': true,
      });

      final notification = js.JsObject(notificationApi, [titulo, options]);

      notification['onclick'] = () {
        js.context.callMethod('focus');
        notification.callMethod('close');
        aoClicar(dados);
      };
    } else if (permission == 'default') {
      notificationApi.callMethod('requestPermission').then((result) {
        if (result == 'granted') {
          exibirNotificacaoWeb(titulo, corpo, dados, aoClicar);
        }
      });
    }
  } catch (_) {}
}