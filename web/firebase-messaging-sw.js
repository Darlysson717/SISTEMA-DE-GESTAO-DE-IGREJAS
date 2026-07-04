// Service worker do Firebase Cloud Messaging (push em segundo plano na web).
//
// A versão dos scripts abaixo (11.9.1) DEVE acompanhar a versão do Firebase
// JS SDK injetada pelo firebase_core_web (ver firebase_sdk_version.dart do
// pacote). Reveja este arquivo ao atualizar os pacotes firebase_* do Flutter.
//
// A config abaixo duplica a seção `web` de lib/firebase_options.dart —
// o service worker não lê código Dart. Manter os dois em sincronia.
importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDKfUM3YPPWlp4T51AV1YYAoGZf1uTc3RQ",
  appId: "1:46968246148:web:4b39e0f910ff3d6c6397d1",
  messagingSenderId: "46968246148",
  projectId: "app-iadet",
  authDomain: "app-iadet.firebaseapp.com",
  storageBucket: "app-iadet.firebasestorage.app",
});

const messaging = firebase.messaging();

// IMPORTANTE: mensagens com payload `notification` (o que a Edge Function
// `enviar-notificacao` sempre envia) são exibidas AUTOMATICAMENTE pelo SDK
// quando o app está em segundo plano. Chamar showNotification para elas
// duplicaria a notificação — aqui só tratamos mensagens data-only.
messaging.onBackgroundMessage((payload) => {
  if (!payload.notification && payload.data && payload.data.titulo) {
    self.registration.showNotification(payload.data.titulo, {
      body: payload.data.corpo || "",
      icon: "icons/Icon-192.png",
      data: payload.data,
    });
  }
});
