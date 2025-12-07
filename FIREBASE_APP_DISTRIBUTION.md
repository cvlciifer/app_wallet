# Instrucciones de Firebase App Distribution

## ✅ Implementación Completada

Se ha configurado exitosamente el SDK de Firebase App Distribution en tu proyecto Android.

## 📋 Pasos Previos Requeridos

### 1. Habilitar la API de App Distribution Tester

⚠️ **IMPORTANTE**: Antes de compilar, debes realizar estos pasos en la Consola de Google Cloud:

1. Abre la [Consola de Google Cloud](https://console.cloud.google.com/)
2. Selecciona tu proyecto de Firebase
3. Busca "Firebase App Distribution API" o "App Testers API"
4. Haz clic en **Habilitar**

## 🔧 Cambios Realizados

### 1. **android/app/build.gradle**
   - ✅ Agregadas dependencias del SDK de App Distribution:
     - `firebase-appdistribution-api-ktx` (para todas las variantes)
     - `firebase-appdistribution` (solo para variante beta)
   - ✅ Configuradas variantes de producto (flavors):
     - **production**: Para compilaciones de Google Play Store
     - **beta**: Para pruebas con App Distribution

### 2. **MainActivity.kt**
   - ✅ Implementada notificación automática de comentarios
   - ✅ Manejo seguro de excepciones (no afecta variante production)
   - ✅ Configurado con nivel de interrupción HIGH

### 3. **strings.xml**
   - ✅ Creado archivo de recursos con textos informativos
   - ✅ Mensaje de privacidad sobre recopilación de datos

### 4. **AndroidManifest.xml**
   - ✅ Agregado permiso `POST_NOTIFICATIONS` (requerido para Android 13+)

## 🚀 Cómo Compilar

### Para versión BETA (con App Distribution):
```bash
flutter build apk --flavor beta --release
```

### Para versión PRODUCTION (para Google Play):
```bash
flutter build apk --flavor production --release
```

### Para iOS (tu comando original funcionará):
```bash
flutter build ios --release
```

## 🧪 Pruebas

### Prueba Local (Modo Desarrollador):
```bash
# Habilitar modo dev
adb shell setprop debug.firebase.appdistro.devmode true

# Compilar y probar
flutter build apk --flavor beta --debug
flutter install

# Deshabilitar después
adb shell setprop debug.firebase.appdistro.devmode false
```

### Prueba End-to-End:
1. Compila la versión beta: `flutter build apk --flavor beta --release`
2. Sube el APK a Firebase App Distribution (consola o CLI)
3. Distribuye a un grupo de prueba
4. Descarga desde la app de App Distribution
5. Verás una notificación persistente para enviar comentarios

## ⚠️ IMPORTANTE: Antes de Publicar en Google Play

**NUNCA** uses la variante `beta` para Google Play Store. Siempre usa:
```bash
flutter build apk --flavor production --release
```

La variante `production` NO incluye el SDK completo de App Distribution, solo la API, por lo que cumple con las políticas de Google Play.

## 📱 Características Implementadas

1. **Notificación Persistente**: Los testers verán una notificación que pueden presionar para enviar comentarios
2. **Captura Automática**: Se captura la pantalla actual al enviar comentarios
3. **Autenticación Automática**: Solicita login con Google si es necesario
4. **Recopilación de Datos**: Formulario completo para comentarios detallados

## 🔗 Recursos Adicionales

- [Firebase App Distribution Docs](https://firebase.google.com/docs/app-distribution)
- [Subir APK via CLI](https://firebase.google.com/docs/app-distribution/android/distribute-cli)
- [Gestionar Testers](https://firebase.google.com/docs/app-distribution/manage-testers)

## 🆘 Solución de Problemas

Si los testers no pueden enviar comentarios:
1. Verifica que la API de App Distribution esté habilitada
2. Confirma que `google-services.json` esté actualizado
3. Asegúrate de distribuir la variante **beta**, no production
4. Verifica que el tester esté autenticado con la cuenta correcta

---

**Siguiente paso**: Habilita la API en Google Cloud Console y luego compila con `flutter build apk --flavor beta --release`
