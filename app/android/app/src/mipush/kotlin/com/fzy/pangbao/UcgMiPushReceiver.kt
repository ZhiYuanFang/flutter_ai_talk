package com.fzy.pangbao

import android.content.Context
import com.xiaomi.mipush.sdk.ErrorCode
import com.xiaomi.mipush.sdk.MiPushClient
import com.xiaomi.mipush.sdk.MiPushCommandMessage
import com.xiaomi.mipush.sdk.PushMessageReceiver

class UcgMiPushReceiver : PushMessageReceiver() {
    override fun onReceiveRegisterResult(context: Context, message: MiPushCommandMessage) {
        if (MiPushClient.COMMAND_REGISTER != message.command) return
        if (message.resultCode != ErrorCode.SUCCESS.toLong()) return
        val regId = message.commandArguments?.firstOrNull()?.trim().orEmpty()
        if (regId.isNotEmpty()) {
            UcgPushBridge.publishToken("mipush", regId)
        }
    }

    override fun onCommandResult(context: Context, message: MiPushCommandMessage) {
        if (MiPushClient.COMMAND_REGISTER != message.command) return
        if (message.resultCode != ErrorCode.SUCCESS.toLong()) return
        val regId = message.commandArguments?.firstOrNull()?.trim().orEmpty()
        if (regId.isNotEmpty()) {
            UcgPushBridge.publishToken("mipush", regId)
        }
    }
}
