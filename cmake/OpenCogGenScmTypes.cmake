#
# OpenCogGenScmTypes.cmake
#
# Definitions for automatically building a Scheme `atom_types.scm`
# file, given a master file `atom_types.script`.
#
# Example usage:
# OPENCOG_SCM_ATOMTYPES(atom_types.script core_types.scm)
#
# ===================================================================

MACRO(OPENCOG_SCM_SETUP SCM_FILE)
	IF (NOT SCM_FILE)
		MESSAGE(FATAL_ERROR "OPENCOG_SCM_ATOMTYPES missing SCM_FILE")
	ENDIF (NOT SCM_FILE)

	MESSAGE(DEBUG "Generating Scheme Atom Type definitions from ${SCRIPT_FILE}.")

	FILE(WRITE "${SCM_FILE}"
		"\n"
		"; DO NOT EDIT THIS FILE! This file was automatically\n"
		"; generated from atom definitions in\n"
		"; ${SCRIPT_FILE}\n"
		"; by the macro OPENCOG_SCM_ATOMTYPES\n"
		";\n"
		"; This file contains basic scheme wrappers for atom creation.\n"
		";\n"
	)
ENDMACRO(OPENCOG_SCM_SETUP SCM_FILE)

# Print out the scheme definitions
MACRO(OPENCOG_SCM_WRITE_DEFS SCM_FILE)
	FILE(APPEND "${SCM_FILE}"
		"(define-public ${TYPE_NAME}Type (cog-type->int '${TYPE_NAME}))\n"
	)

	IF (ISVALUE STREQUAL "VALUE" OR ISSTREAM STREQUAL "STREAM")
		FILE(APPEND "${SCM_FILE}"
			"(define-public (${TYPE_NAME} . x)\n"
			"\t(apply cog-new-value (cons ${TYPE_NAME}Type x)))\n"
			"(set-procedure-property! ${TYPE_NAME} 'documentation\n"
			"\" ${TYPE_NAME} -- See https://wiki.opencog.org/w/${TYPE_NAME} for documentation.\")\n"
		)
	ENDIF (ISVALUE STREQUAL "VALUE" OR ISSTREAM STREQUAL "STREAM")

	IF (ISNODE STREQUAL "NODE")
		FILE(APPEND "${SCM_FILE}"
			"(define-public (${TYPE_NAME} . x)\n"
			"\t(apply cog-new-node (cons ${TYPE_NAME}Type x)))\n"
			"(set-procedure-property! ${TYPE_NAME} 'documentation\n"
			"\" ${TYPE_NAME} -- See https://wiki.opencog.org/w/${TYPE_NAME} for documentation.\")\n"
		)
		IF (NOT SHORT_NAME STREQUAL "")
			FILE(APPEND "${SCM_FILE}"
				"(define-public (${SHORT_NAME} . x)\n"
				"\t(apply cog-new-node (cons ${TYPE_NAME}Type x)))\n"
				"(set-procedure-property! ${SHORT_NAME} 'documentation\n"
				"\" ${TYPE_NAME} -- See https://wiki.opencog.org/w/${TYPE_NAME} for documentation.\")\n"
			)
		ENDIF (NOT SHORT_NAME STREQUAL "")
	ENDIF (ISNODE STREQUAL "NODE")

	IF (ISLINK STREQUAL "LINK")
		FILE(APPEND "${SCM_FILE}"
			"(define-public (${TYPE_NAME} . x)\n"
			"\t(apply cog-new-link (cons ${TYPE_NAME}Type x)))\n"
			"(set-procedure-property! ${TYPE_NAME} 'documentation\n"
			"\" ${TYPE_NAME} -- See https://wiki.opencog.org/w/${TYPE_NAME} for documentation.\")\n"
		)
		IF (NOT SHORT_NAME STREQUAL "")
			FILE(APPEND "${SCM_FILE}"
				"(define-public (${SHORT_NAME} . x)\n"
				"\t(apply cog-new-link (cons ${TYPE_NAME}Type x)))\n"
				"(set-procedure-property! ${SHORT_NAME} 'documentation\n"
				"\" ${TYPE_NAME} -- See https://wiki.opencog.org/w/${TYPE_NAME} for documentation.\")\n"
			)
		ENDIF (NOT SHORT_NAME STREQUAL "")
	ENDIF (ISLINK STREQUAL "LINK")

	# Create and then add.
	IF (ISATOMSPACE STREQUAL "ATOM_SPACE")
		FILE(APPEND "${SCM_FILE}"
			"(define-public (AtomSpace . x) (cog-add-atomspace (cog-new-atomspace x)))\n"
		)
	ENDIF (ISATOMSPACE STREQUAL "ATOM_SPACE")

	IF (ISAST STREQUAL "AST")
		FILE(APPEND "${SCM_FILE}"
			"(define-public (${TYPE_NAME} . x)\n"
			"\t(apply cog-new-ast (cons ${TYPE_NAME}Type x)))\n"
		)
	ENDIF (ISAST STREQUAL "AST")
ENDMACRO(OPENCOG_SCM_WRITE_DEFS SCM_FILE)

# ------------
# Main entry point.
MACRO(OPENCOG_SCM_ATOMTYPES SCRIPT_FILE SCM_FILE)

	OPENCOG_SCM_SETUP(${SCM_FILE})
	FILE(STRINGS "${SCRIPT_FILE}" TYPE_SCRIPT_CONTENTS)
	FOREACH (LINE ${TYPE_SCRIPT_CONTENTS})
		OPENCOG_TYPEINFO_REGEX()
		IF (MATCHED AND CMAKE_MATCH_1)

			OPENCOG_TYPEINFO_SETUP()
			OPENCOG_SCM_WRITE_DEFS(${SCM_FILE})    # Print out the scheme definitions
		ELSEIF (NOT MATCHED)
			MESSAGE(FATAL_ERROR "Invalid line in ${SCRIPT_FILE} file: [${LINE}]")
		ENDIF ()
	ENDFOREACH (LINE)

ENDMACRO()

#####################################################################
