package com.example.tv_indoor

import android.os.Bundle
import android.webkit.WebView
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            // Habilitar debugging do WebView em modo debug
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
            
            // Configurar CookieManager para aceitar cookies
            val cookieManager = CookieManager.getInstance()
            cookieManager.setAcceptCookie(true)
            
            // Manter a tela sempre ligada para TV Box
            window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            
        } catch (e: Exception) {
            // Se alguma configuração falhar, continuar sem ela
            println("Erro ao configurar WebView: ${e.message}")
        }
    }
}
