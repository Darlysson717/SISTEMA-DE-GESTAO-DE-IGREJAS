# Solução para Erro do Gradle Durante Build

## ❌ Erro Encontrado:

```
JVM crash log found: file:///C:/Users/darly/Desktop/app%20iadet/android/hs_err_pid123240.log
FAILURE: Build failed with an exception.
* What went wrong:
Gradle build daemon disappeared unexpectedly (it may have been killed or may have crashed)
```

**Causa:** O Gradle está usando muita memória e o Java está crashando.

---

## ✅ Soluções (tente na ordem):

### **Solução 1: Aumentar Memória do Gradle**

1. Abra o arquivo: `android/gradle.properties`

2. Adicione ou altere estas linhas:

```properties
# Aumentar memória do Gradle
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8

# Desativar daemon se necessário (opcional)
org.gradle.daemon=false
```

3. Salve o arquivo

---

### **Solução 2: Parar o Daemon do Gradle**

Execute no terminal:

```bash
cd android
./gradlew --stop
```

Ou no Windows:
```bash
cd android
gradlew --stop
```

Depois tente compilar novamente:
```bash
flutter build apk --release
```

---

### **Solução 3: Limpar e Recompilar**

```bash
# Limpar tudo
flutter clean

# Parar daemon
cd android
gradlew --stop
cd ..

# Recompilar
flutter pub get
flutter build apk --release
```

---

### **Solução 4: Verificar Memória Disponível**

Verifique se seu computador tem memória suficiente:

```bash
# Verificar memória disponível (Windows)
wmic OS get TotalVisibleMemorySize,FreePhysicalMemory
```

**Recomendação:** 
- Mínimo: 4 GB RAM livre
- Ideal: 8 GB RAM livre

---

### **Solução 5: Fechar Outros Programas**

Feche programas que consomem memória:
- Navegadores (Chrome, Edge, etc.)
- IDEs (VS Code, Android Studio)
- Outros apps pesados

Depois tente compilar novamente.

---

### **Solução 6: Reduzir Paralelismo**

Edite `android/gradle.properties`:

```properties
# Reduzir paralelismo
org.gradle.parallel=false
org.gradle.configureondemand=true
```

---

### **Solução 7: Verificar Log de Crash (opcional)**

Se quiser ver o log completo do crash:

1. Abra o arquivo: `C:/Users/darly/Desktop/app iadet/android/hs_err_pid123240.log`
2. Procure por linhas com "ERROR" ou "OutOfMemoryError"
3. Isso vai confirmar se é realmente falta de memória

---

## 🚀 Tentativa Rápida (recomendada):

Execute estes comandos na ordem:

```bash
# 1. Parar todos os processos Gradle
cd android
gradlew --stop
cd ..

# 2. Limpar projeto
flutter clean

# 3. Aumentar memória (se não existir, adicione no gradle.properties)
echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m" >> android/gradle.properties

# 4. Recompilar
flutter pub get
flutter build apk --release
```

---

## 📊 Verificar se Funcionou:

Se o build começar e mostrar:
```
Running Gradle task 'assembleRelease'...
```

E depois de alguns minutos mostrar:
```
✓ Built build\app\outputs\flutter-apk\app-release.apk
```

**Pronto!** O APK foi compilado com sucesso.

---

## ⚠️ Se Nada Funcionar:

### **Opção A: Compilar em Modo Debug (mais rápido)**
```bash
flutter build apk --debug
```

### **Opção B: Compilar AAB (Android App Bundle)**
```bash
flutter build appbundle --release
```

### **Opção C: Usar Build do Android Studio**
1. Abra o projeto no Android Studio
2. Vá em Build → Build Bundle(s) / APK(s) → Build APK(s)

---

## 🔍 Causa do Problema:

O erro acontece porque:
1. O Gradle está tentando compilar o app
2. O Java precisa de mais memória do que o disponível
3. O sistema operacional mata o processo (OOM Killer)
4. O Gradle crasha e aborta o build

**Não é um erro no código do app!** É apenas um problema de configuração de memória.

---

## ✅ Após Conseguir Compilar:

Depois que o APK for gerado, continue com o processo normal:

1. Crie a release no GitHub
2. Cadastre no Supabase
3. Teste no app

---

Pronto! Tente as soluções acima e o build deve funcionar! 🎯