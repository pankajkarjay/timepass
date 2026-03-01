package com.timepass.meshfamily

import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Base64
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.google.android.gms.location.LocationServices
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import com.google.gson.Gson
import java.io.ByteArrayOutputStream
import java.util.UUID

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            MaterialTheme {
                MeshFamilyApp()
            }
        }
    }
}

data class MeshMessage(
    val id: String = UUID.randomUUID().toString(),
    val sender: String,
    val body: String,
    val type: String = "text",
    val imageBase64: String? = null,
    val lat: Double? = null,
    val lon: Double? = null,
    val timestampMs: Long = System.currentTimeMillis(),
)

private class MeshController(private val context: Context, private val onMessage: (MeshMessage) -> Unit) {
    private val serviceId = "com.timepass.meshfamily.SERVICE"
    private val strategy = Strategy.P2P_CLUSTER
    private val gson = Gson()
    private val connectionsClient: ConnectionsClient = Nearby.getConnectionsClient(context)
    private val connectedEndpoints = mutableSetOf<String>()

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            val bytes = payload.asBytes() ?: return
            val msg = gson.fromJson(String(bytes), MeshMessage::class.java)
            onMessage(msg)
            relay(msg, skip = endpointId)
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) = Unit
    }

    private val lifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            connectedEndpoints.add(endpointId)
        }

        override fun onDisconnected(endpointId: String) {
            connectedEndpoints.remove(endpointId)
        }
    }

    private val discoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            connectionsClient.requestConnection("MeshFamily", endpointId, lifecycleCallback)
        }

        override fun onEndpointLost(endpointId: String) {
            connectedEndpoints.remove(endpointId)
        }
    }

    fun start() {
        connectionsClient.startAdvertising(
            "MeshFamily",
            serviceId,
            lifecycleCallback,
            AdvertisingOptions.Builder().setStrategy(strategy).build(),
        )
        connectionsClient.startDiscovery(
            serviceId,
            discoveryCallback,
            DiscoveryOptions.Builder().setStrategy(strategy).build(),
        )
    }

    fun broadcast(message: MeshMessage) {
        val payload = Payload.fromBytes(gson.toJson(message).toByteArray())
        if (connectedEndpoints.isNotEmpty()) {
            connectionsClient.sendPayload(connectedEndpoints.toList(), payload)
        }
    }

    private fun relay(message: MeshMessage, skip: String) {
        val endpoints = connectedEndpoints.filterNot { it == skip }
        if (endpoints.isEmpty()) return
        val payload = Payload.fromBytes(gson.toJson(message).toByteArray())
        connectionsClient.sendPayload(endpoints, payload)
    }
}

@Composable
private fun MeshFamilyApp() {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("mesh_family", Context.MODE_PRIVATE) }
    var passkey by remember { mutableStateOf("") }
    var loggedIn by remember { mutableStateOf(false) }
    var memberName by remember { mutableStateOf(prefs.getString("member_name", "") ?: "") }
    var text by remember { mutableStateOf("") }
    val messages = remember { mutableStateListOf<MeshMessage>() }
    val mesh = remember { MeshController(context) { messages.add(it) } }

    val locationClient = remember { LocationServices.getFusedLocationProviderClient(context) }
    val imagePicker = rememberLauncherForActivityResult(PickVisualMedia()) { uri: Uri? ->
        if (uri != null) {
            val encoded = uriToBase64(context, uri)
            val msg = MeshMessage(sender = memberName, body = "[Image]", type = "image", imageBase64 = encoded)
            messages.add(msg)
            mesh.broadcast(msg)
        }
    }

    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { _ ->
        mesh.start()
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (!loggedIn) {
            Text("Family Mesh Login")
            OutlinedTextField(value = memberName, onValueChange = { memberName = it }, label = { Text("Your name") })
            OutlinedTextField(value = passkey, onValueChange = { passkey = it }, label = { Text("Family passkey") })
            Button(onClick = {
                val savedPasskey = prefs.getString("family_passkey", null)
                if (savedPasskey == null) {
                    prefs.edit().putString("family_passkey", passkey).putString("member_name", memberName).apply()
                    loggedIn = true
                } else if (savedPasskey == passkey) {
                    prefs.edit().putString("member_name", memberName).apply()
                    loggedIn = true
                }
            }) { Text("Enter") }
            Text("First person sets the passkey once, then share it privately with family.")
            return@Column
        }

        Button(onClick = {
            val permissions = mutableListOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_ADVERTISE,
            )
            if (Build.VERSION.SDK_INT < 33) {
                permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            } else {
                permissions.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
            permissionLauncher.launch(permissions.toTypedArray())
        }) { Text("Start Mesh") }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            OutlinedTextField(value = text, onValueChange = { text = it }, modifier = Modifier.weight(1f), label = { Text("Message") })
            Button(onClick = {
                if (text.isNotBlank()) {
                    val msg = MeshMessage(sender = memberName, body = text)
                    messages.add(msg)
                    mesh.broadcast(msg)
                    text = ""
                }
            }) { Text("Send") }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = {
                imagePicker.launch(PickVisualMediaRequest(PickVisualMedia.ImageOnly))
            }) { Text("Send Image") }

            Button(onClick = {
                locationClient.lastLocation.addOnSuccessListener { loc ->
                    val msg = MeshMessage(
                        sender = memberName,
                        body = "SOS! Need help.",
                        type = "sos",
                        lat = loc?.latitude,
                        lon = loc?.longitude,
                    )
                    messages.add(msg)
                    mesh.broadcast(msg)
                }
            }) { Text("SOS + Location") }
        }

        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(messages, key = { it.id }) { msg ->
                val suffix = when (msg.type) {
                    "sos" -> " [SOS ${msg.lat ?: "?"}, ${msg.lon ?: "?"}]"
                    "image" -> " [Image attached]"
                    else -> ""
                }
                Text("${msg.sender}: ${msg.body}$suffix")
            }
        }
    }
}

private fun uriToBase64(context: Context, uri: Uri): String {
    val bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, uri)
    val out = ByteArrayOutputStream()
    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 60, out)
    return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
}
