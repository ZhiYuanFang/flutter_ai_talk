package com.fzy.pangbao

import com.huawei.hms.push.HmsMessageService

class UcgHmsMessageService : HmsMessageService() {
    override fun onNewToken(token: String?) {
        val normalized = token?.trim().orEmpty()
        if (normalized.isNotEmpty()) {
            UcgPushBridge.publishToken("hms", normalized)
        }
    }
}
