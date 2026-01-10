// ============================================================================
// CLICodeSign.js - Command-line code signing for PixInsight
// ============================================================================
//
// Usage from terminal:
//   PixInsight -n --automation-mode -r="path/to/CLICodeSign.js,keys=path/to/keys.xssk,pass=yourpassword,files=file1.js;file2.js;file3.xri" --force-exit
//
// Parameters (comma-separated after script path):
//   keys=<path>     Path to your .xssk signing keys file
//   pass=<password> Password for the keys file
//   files=<list>    Semicolon-separated list of files to sign
//
// Example:
//   PixInsight -n --automation-mode -r="/path/to/CLICodeSign.js,keys=/home/user/mykeys.xssk,pass=MySecretPass,files=/path/to/Script1.js;/path/to/Script2.js" --force-exit
//
// ============================================================================

#feature-id    Utilities > CLICodeSign
#script-id     CLICodeSign
#feature-info  Command-line code signing utility for batch signing scripts

function parseArguments() {
   var args = {
      keys: null,
      pass: null,
      files: []
   };

   // Check if we have jsArguments (passed via -r=)
   if (typeof jsArguments !== 'undefined' && jsArguments.length > 0) {
      for (var i = 0; i < jsArguments.length; i++) {
         var arg = jsArguments[i];
         if (arg.indexOf('keys=') === 0) {
            args.keys = arg.substring(5);
         } else if (arg.indexOf('pass=') === 0) {
            args.pass = arg.substring(5);
         } else if (arg.indexOf('files=') === 0) {
            var fileList = arg.substring(6);
            args.files = fileList.split(';').filter(function(f) { return f.length > 0; });
         }
      }
   }

   return args;
}

function signFile(keysFile, password, filePath) {
   try {
      // Determine if it's an XRI file or script file
      var isXRI = filePath.toLowerCase().endsWith('.xri');

      if (isXRI) {
         // For XRI files, signature is embedded
         Security.signRepositoryFile(keysFile, password, [], filePath);
         console.writeln("  Signed (embedded): " + filePath);
      } else {
         // For JS files, creates .xsgn alongside
         Security.generateScriptSignatureFile(keysFile, password, [], filePath);
         var xsgnPath = filePath.replace(/\.js$/i, '.xsgn');
         console.writeln("  Signed: " + filePath);
         console.writeln("  Created: " + xsgnPath);
      }
      return true;
   } catch (e) {
      console.criticalln("  FAILED: " + filePath);
      console.criticalln("  Error: " + e.message);
      return false;
   }
}

function main() {
   console.writeln("");
   console.writeln("===========================================");
   console.writeln("CLICodeSign - Command-line Code Signing");
   console.writeln("===========================================");
   console.writeln("");

   var args = parseArguments();

   // Validate arguments
   if (!args.keys) {
      console.criticalln("Error: Missing 'keys' parameter (path to .xssk file)");
      console.writeln("Usage: keys=<path>,pass=<password>,files=<file1;file2;...>");
      return;
   }

   if (!args.pass) {
      console.criticalln("Error: Missing 'pass' parameter (keys file password)");
      return;
   }

   if (args.files.length === 0) {
      console.criticalln("Error: Missing 'files' parameter (semicolon-separated file list)");
      return;
   }

   // Check if keys file exists
   if (!File.exists(args.keys)) {
      console.criticalln("Error: Keys file not found: " + args.keys);
      return;
   }

   console.writeln("Keys file: " + args.keys);
   console.writeln("Files to sign: " + args.files.length);
   console.writeln("");

   var succeeded = 0;
   var failed = 0;

   for (var i = 0; i < args.files.length; i++) {
      var filePath = args.files[i].trim();

      if (!File.exists(filePath)) {
         console.warningln("  File not found: " + filePath);
         failed++;
         continue;
      }

      console.writeln("Signing: " + File.extractName(filePath));

      if (signFile(args.keys, args.pass, filePath)) {
         succeeded++;
      } else {
         failed++;
      }
   }

   console.writeln("");
   console.writeln("===========================================");
   console.writeln("Results: " + succeeded + " succeeded, " + failed + " failed");
   console.writeln("===========================================");
}

main();
