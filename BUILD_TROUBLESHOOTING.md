# 🔧 Guia de Solução de Problemas de Build

## ❌ Erro: `CMakeFiles\CMakeTmp\.ninja_deps: O arquivo já está sendo usado por outro processo`

### 🎯 Causa
Este erro ocorre quando há processos Java/Gradle em execução que estão bloqueando arquivos de build.

### ✅ Solução Passo a Passo

1. **Encerrar processos Java:**
   ```powershell
   taskkill /f /im "java.exe" /t
   ```

2. **Remover arquivos CMake conflitantes:**
   ```powershell
   Remove-Item -Path "build\.cxx" -Recurse -Force -ErrorAction SilentlyContinue
   ```

3. **Limpeza completa do projeto:**
   ```powershell
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   ```

4. **Aceitar licenças Android (se necessário):**
   ```powershell
   flutter doctor --android-licenses
   ```

5. **Reinstalar dependências:**
   ```powershell
   flutter pub get
   ```

6. **Executar o projeto:**
   ```powershell
   flutter run
   ```

## 🔄 Script de Limpeza Completa (PowerShell)

```powershell
# Encerrar processos que podem causar conflito
taskkill /f /im "java.exe" /t 2>$null
taskkill /f /im "gradle*" /t 2>$null

# Remover arquivos problemáticos
Remove-Item -Path "build\.cxx" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

# Limpeza Flutter
flutter clean

# Limpeza Gradle
cd android
./gradlew clean
cd ..

# Reinstalar dependências
flutter pub get

# Executar
flutter run
```

## 🚨 Outros Erros Comuns

### CMake não encontrado
- **Solução**: Instalar C++ CMake tools for Windows no Visual Studio

### Licenças Android não aceitas
- **Solução**: `flutter doctor --android-licenses`

### Conflito de versões do Gradle
- **Solução**: Executar `./gradlew --stop` e depois `./gradlew clean`

### Device não detectado
- **Solução**: `flutter devices` para listar dispositivos disponíveis

## 📊 Verificações de Status

```powershell
# Verificar status geral do Flutter
flutter doctor

# Verificar dispositivos disponíveis
flutter devices

# Verificar dependências desatualizadas
flutter pub outdated
```

---
**Última atualização**: 22/08/2025
**Status**: Problemas de CMake/Gradle resolvidos ✅
