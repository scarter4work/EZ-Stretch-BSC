// DumpKeys.js - Extract signing keys for standalone signing tool
// Run in PixInsight to extract keys to JSON format
//
// Usage:
//   1. Write password to /tmp/.pi_codesign_pass
//   2. Run this script in PixInsight
//   3. Keys are written to ~/.pi_signing_keys.json (chmod 600)

#feature-id    Utilities > DumpKeys
#script-id     DumpKeys

var KEYS_FILE = "/home/scarter4work/projects/keys/scarter4work_keys.xssk";
var PASS_FILE = "/tmp/.pi_codesign_pass";
var OUTPUT_FILE = "/tmp/.pi_signing_keys.json";

function getPassword() {
   if (File.exists(PASS_FILE)) {
      try {
         var pass = File.readTextFile(PASS_FILE);
         return pass.trim();
      } catch (e) {
         console.warningln("Error reading password file: " + e.message);
      }
   }
   return null;
}

function byteArrayToHex(ba) {
   var hex = "";
   for (var i = 0; i < ba.length; i++) {
      var b = ba.at(i);
      hex += ("0" + (b & 0xff).toString(16)).slice(-2);
   }
   return hex;
}

function main() {
   console.writeln("");
   console.writeln("===========================================");
   console.writeln("DumpKeys - Key Extraction Utility");
   console.writeln("===========================================");
   console.writeln("");

   var password = getPassword();
   if (!password) {
      console.criticalln("Error: No password. Write it to " + PASS_FILE);
      return;
   }

   if (!File.exists(KEYS_FILE)) {
      console.criticalln("Error: Keys file not found: " + KEYS_FILE);
      return;
   }

   console.writeln("Loading keys from: " + KEYS_FILE);

   try {
      var keys = Security.loadSigningKeysFile(KEYS_FILE, password);

      if (!keys.valid) {
         console.criticalln("Error: Invalid keys or wrong password");
         return;
      }

      console.noteln("Developer ID: " + keys.developerId);
      console.noteln("Public key length: " + keys.publicKey.length + " bytes");
      console.noteln("Private key length: " + keys.privateKey.length + " bytes");

      var pubHex = byteArrayToHex(keys.publicKey);
      var privHex = byteArrayToHex(keys.privateKey);

      // Ed25519 keys should be 32 bytes (public) and 32 or 64 bytes (private)
      if (keys.publicKey.length != 32) {
         console.warningln("Warning: Public key is " + keys.publicKey.length + " bytes, expected 32");
      }
      if (keys.privateKey.length != 32 && keys.privateKey.length != 64) {
         console.warningln("Warning: Private key is " + keys.privateKey.length + " bytes, expected 32 or 64");
      }

      // Write as JSON for Python tool
      var json = '{\n';
      json += '  "developerId": "' + keys.developerId + '",\n';
      json += '  "publicKey": "' + pubHex + '",\n';
      json += '  "privateKey": "' + privHex + '"\n';
      json += '}\n';

      var out = new File();
      out.createForWriting(OUTPUT_FILE);
      out.write(ByteArray.stringToUTF8(json));
      out.close();

      // Set restrictive permissions (owner read/write only)
      // Note: PJSR doesn't have chmod, but the file is in temp dir
      console.noteln("");
      console.noteln("Keys written to: " + OUTPUT_FILE);
      console.warningln("SECURITY: Move this file to a secure location and restrict permissions!");
      console.writeln("");
      console.writeln("For standalone signing, run:");
      console.writeln("  mv /tmp/.pi_signing_keys.json ~/.pi_signing_keys.json");
      console.writeln("  chmod 600 ~/.pi_signing_keys.json");

      // Securely clear keys
      keys.publicKey.secureFill();
      keys.privateKey.secureFill();

   } catch (e) {
      console.criticalln("Error: " + e.message);
   }
}

main();
