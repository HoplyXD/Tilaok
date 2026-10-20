package org.hoplyxd.tilaok.scanner

import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class QrFrameDecoderTest {
    @Test
    fun decodesInvitationFromLocalLumaFrame() {
        val invitation =
            "tilaok://join?lobby=AAAAAAAAAAAAA&host=192.168.1.22&port=27777&protocol=1.1&digest=" +
                "a".repeat(64) + "&code=" + "A".repeat(26) + "&epoch=7"
        val matrix = QRCodeWriter().encode(
            invitation,
            BarcodeFormat.QR_CODE,
            640,
            640,
            mapOf(EncodeHintType.MARGIN to 2),
        )
        val luma = ByteArray(matrix.width * matrix.height) { index ->
            val x = index % matrix.width
            val y = index / matrix.width
            if (matrix[x, y]) 0 else 0xFF.toByte()
        }

        assertEquals(invitation, decode(luma, matrix.width, matrix.height))
    }

    @Test
    fun rejectsInvalidFrameDimensions() {
        assertNull(decode(byteArrayOf(0), 0, 1))
        assertNull(decode(byteArrayOf(0), 2, 2))
    }

    private fun decode(luminance: ByteArray, width: Int, height: Int): String? {
        val type = Class.forName("org.hoplyxd.tilaok.scanner.QrFrameDecoder")
        val decoder = type.getConstructor().newInstance()
        return type.getMethod("decode", ByteArray::class.java, Int::class.javaPrimitiveType, Int::class.javaPrimitiveType)
            .invoke(decoder, luminance, width, height) as String?
    }
}
