package com.example.app_wallet

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import com.google.firebase.appdistribution.FirebaseAppDistribution
import com.google.firebase.appdistribution.InterruptionLevel

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Configurar notificación de comentarios de App Distribution
        // Solo se ejecutará si el SDK completo está incluido (variante beta)
        try {
            FirebaseAppDistribution.getInstance().showFeedbackNotification(
                // Texto informando sobre la recopilación de datos de comentarios
                R.string.feedback_additional_info,
                // Nivel de interrupción de la notificación
                InterruptionLevel.HIGH
            )
        } catch (e: Exception) {
            // El SDK completo no está disponible (variante de producción)
            // No hacer nada, el código continúa normalmente
        }
    }
}
