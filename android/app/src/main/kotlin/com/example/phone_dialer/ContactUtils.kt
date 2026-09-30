package com.example.phone_dialer

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

object ContactUtils {
    fun getContactName(context: Context, phoneNumber: String): String? {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return null
        }
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
        var contactName: String? = null
        val cursor = context.contentResolver.query(uri, projection, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val index = it.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                if (index != -1) {
                    contactName = it.getString(index)
                }
            }
        }
        return contactName
    }
}
