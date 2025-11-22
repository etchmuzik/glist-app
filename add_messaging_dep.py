import re
import uuid

def generate_id():
    return uuid.uuid4().hex[:24].upper()

project_path = '/Users/etch/Downloads/APPS/glist/Glist/Glist.xcodeproj/project.pbxproj'

with open(project_path, 'r') as f:
    content = f.read()

# 1. Find FirebaseFirestore dependency and create FirebaseMessaging dependency
firestore_dep_pattern = re.compile(r'(\s+)([A-F0-9]+) /\* FirebaseFirestore \*/ = \{(\s+isa = XCSwiftPackageProductDependency;[\s\S]+?productName = FirebaseFirestore;[\s\S]+?\};)')
match = firestore_dep_pattern.search(content)

if not match:
    print("Could not find FirebaseFirestore dependency")
    exit(1)

indent = match.group(1)
firestore_dep_id = match.group(2)
firestore_dep_body = match.group(3)

messaging_dep_id = "DEADBEEF0000000000000001"
messaging_dep_body = firestore_dep_body.replace("FirebaseFirestore", "FirebaseMessaging")

new_dep_entry = f"{indent}{messaging_dep_id} /* FirebaseMessaging */ = {{{messaging_dep_body}"

# Insert after the Firestore entry
content = content.replace(match.group(0), match.group(0) + "\n" + new_dep_entry)

# 2. Find FirebaseFirestore build file and create FirebaseMessaging build file
firestore_build_pattern = re.compile(r'(\s+)([A-F0-9]+) /\* FirebaseFirestore in Frameworks \*/ = \{isa = PBXBuildFile; productRef = ([A-F0-9]+) /\* FirebaseFirestore \*/; \};')
match = firestore_build_pattern.search(content)

if not match:
    print("Could not find FirebaseFirestore build file")
    exit(1)

indent = match.group(1)
firestore_build_id = match.group(2)
# firestore_dep_ref = match.group(3) # Should match firestore_dep_id

messaging_build_id = "DEADBEEF0000000000000002"
new_build_entry = f"{indent}{messaging_build_id} /* FirebaseMessaging in Frameworks */ = {{isa = PBXBuildFile; productRef = {messaging_dep_id} /* FirebaseMessaging */; }};"

# Insert after the Firestore entry
content = content.replace(match.group(0), match.group(0) + "\n" + new_build_entry)

# 3. Add to PBXFrameworksBuildPhase
frameworks_phase_pattern = re.compile(r'(isa = PBXFrameworksBuildPhase;[\s\S]+?files = \()([\s\S]+?)(\);)')
match = frameworks_phase_pattern.search(content)

if not match:
    print("Could not find PBXFrameworksBuildPhase")
    exit(1)

files_content = match.group(2)
new_file_line = f"\n\t\t\t\t{messaging_build_id} /* FirebaseMessaging in Frameworks */,"
new_files_content = files_content + new_file_line

content = content.replace(files_content, new_files_content)

# 4. Add to PBXNativeTarget packageProductDependencies
native_target_pattern = re.compile(r'(isa = PBXNativeTarget;[\s\S]+?packageProductDependencies = \()([\s\S]+?)(\);)')
match = native_target_pattern.search(content)

if not match:
    print("Could not find PBXNativeTarget packageProductDependencies")
    exit(1)

deps_content = match.group(2)
new_dep_line = f"\n\t\t\t\t{messaging_dep_id} /* FirebaseMessaging */,"
new_deps_content = deps_content + new_dep_line

content = content.replace(deps_content, new_deps_content)

with open(project_path, 'w') as f:
    f.write(content)

print("Successfully added FirebaseMessaging to project.pbxproj")
