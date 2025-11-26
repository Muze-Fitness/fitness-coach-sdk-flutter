package com.example.zing_sdk_flutter

import coach.zing.fitness.coach.SdkApplication
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class FlutterApplication : SdkApplication() {

    override fun onCreate() {
        super.onCreate()
    }
}