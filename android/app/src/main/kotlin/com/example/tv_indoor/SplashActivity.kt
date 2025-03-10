package com.example.tv_indoor

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import com.airbnb.lottie.LottieAnimationView

class SplashActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)

        // Aplica fade in na LottieAnimationView
        val lottieView = findViewById<LottieAnimationView>(R.id.lottieAnimationView)
        lottieView.animate().alpha(1f).setDuration(1000).start()

        // Exemplo: esperar 3 segundos (ou até que o Flutter esteja pronto) e abrir a MainActivity
        Handler().postDelayed({

            // Inicia a FlutterActivity, que carregará o Flutter e a tela de login
            startActivity(Intent(this, MainActivity::class.java))
            finish() // Fecha a SplashActivity

        }, 8000)  
    }
}
