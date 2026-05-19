package com.jakubgawron.cksslavia

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller

/** Status sesji PackageInstaller (log / przyszłe UI). */
class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, -1)
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
        android.util.Log.i(
            TAG,
            "PackageInstaller status=$status msg=${message ?: ""}",
        )
    }

    companion object {
        const val ACTION = "com.jakubgawron.cksslavia.INSTALL_RESULT"
        private const val TAG = "SlaviaInstall"
    }
}
