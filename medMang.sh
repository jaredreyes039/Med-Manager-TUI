#!/bin/bash
# THIS APPLICATION USES GUM "A tool for glamorous shell scripts"
# Github: charmbracelet/gum


# FOR DEV ONLY, UNCOMMENT IF NEEDED
echo $PPID
CONFIG_URL="${HOME}/.config/medMang"

# FUNCTION DECLARATIONS
drawTextHeader(){
	gum style \
	--foreground 120 --border-foreground 220 --border double \
	--align center --width 50 --margin "4 4" --padding "4 4" \
	"${1}" \
	"${2}"
}

drawTextStd(){
	gum style \
		--foreground 120 \
		--margin "2 0" \
		"${1}"
}

drawTextErr(){
	gum style \
		--foreground 50 \
		--margin "2 0" \
		"${1}"
}

recordMedications(){
	for ((i=0; i < ${1}; i++))
	do
		read -p "Name of Medication: " MED_NAME
		read -p "Date of Expiration (MM/YYYY): " MED_EXP
		read -p "Dosage Amount (include units): " MED_DOSE
		read -p "Refills Left: " MED_REFILLS
		read -p "Next Refill (MM/YYYY): " MED_NEXT
		echo "Medication: ${MED_NAME} || Exp: ${MED_EXP} | Dosage: ${MED_DOSE} | Refills: ${MED_REFILLS} | Next Refill: ${MED_NEXT}" >> "${SAVE_DIR}/medMang/medLog.txt"
	done
}

addJournalEntry() {
	drawTextStd "Creating entry..."
	read -p "Enter title: " ENTRY_TITLE 
	touch "${SAVE_DIR}/journal/jrn_${ENTRY_TITLE}.txt"
	drawTextStd "What's on your mind? [CTRL+d to Submit]"
	gum write > "${SAVE_DIR}/journal/jrn_${ENTRY_TITLE}.txt"
	drawTextStd "Entry recorded!"
}

addJournalEntry_Appt() {
	drawTextStd "Creating entry..."
	read -p "Enter title: " ENTRY_TITLE 
	touch "${SAVE_DIR}/appt_journal/jrn_${ENTRY_TITLE}.txt"
	read -p "Appointment Date: " APPT_DATE
	echo $APPT_DATE >> "${SAVE_DIR}/appt_journal/jrn_${ENTRY_TITLE}.txt"
	drawTextStd "What's on your mind? [CTRL+d to Subit]"
	gum write > "${SAVE_DIR}/appt_journal/jrn_${ENTRY_TITLE}.txt"
	drawTextStd "Entry recorded!"
}

# CHECK FOR CONFIG
if ! [[ -d "${HOME}/.config/medMang" ]]; then
	mkdir "${CONFIG_URL}"
	touch "${CONFIG_URL}/medMang.conf"
	echo '
		INIT_CONFIG=0
		SAVE_DIR=
	' > "${CONFIG_URL}/medMang.conf"
else
	source "${CONFIG_URL}/medMang.conf"
fi

PROG_LOOP=1
drawTextHeader "Linux Medication Management TUI" "Author: Jay Reyes C2024"
	while [[ $PROG_LOOP -ne 0 ]]
	do
	if [[ $INIT_CONFIG  -ne 1 ]]; then
		drawTextStd "Let's get setup real fast by adding some medications. The rest can be setup anytime from the main options menu."
		INIT_CONFIG_CHOICE=$(gum choose "Med Logs" "Exit")
		case $INIT_CONFIG_CHOICE in
			"Exit")
				PROG_LOOP=0
		esac
		if [[ "$INIT_CONFIG_CHOICE" == "Med Logs" ]]; then
			REGEX='^[0-9]+$'
			read -p "Let's start with how many meds you are currently taking: " LEN
			if ! [[ $LEN =~ $REGEX ]]; then
				drawTextErr "ERR: Not a number"
				exit 1
			fi
			drawTextStd "Perfect, now what directory do you want to save this file in?"
			DIR_IS_SET=0
			while [ $DIR_IS_SET -ne 1 ];
			do
				read -p "Save Directory: ${HOME}" SET_SAVE_DIR
				SAVE_DIR="${HOME}${SET_SAVE_DIR}"
				mkdir "${SAVE_DIR}/medMang"
				if [ $? -ne 0 ]; then
					drawTextErr "Failed to create directory, maybe it already exists?"
				else
					touch "${SAVE_DIR}/medMang/medLog.txt"
					if [ $? -ne 0 ]; then
						drawTextErr "Failed to create Medication Log, maybe it already exists?"
					else
						DIR_IS_SET=1
					fi
				fi
			done
			sed -i "s#SAVE_DIR=#SAVE_DIR=${SAVE_DIR}/medMang#" "${HOME}/.config/medMang/medMang.conf" 
			sed -i "s#INIT_CONFIG=0#INIT_CONFIG=1#" "${HOME}/.config/medMang/medMang.conf"
			drawTextStd "Enter the following info to record your medications."
			recordMedications $LEN
		fi
	fi				
	if [[ $INIT_CONFIG -ne 0 ]]; then
		drawTextStd "Awesome, where are your files stored?"
			echo "Checking ${SAVE_DIR} for files..."
			if [[ -d "${SAVE_DIR}" ]]; then
				drawTextStd "Files loaded! What are you looking for today?"
				MAIN_CHOICE=$(gum choose "Med Logs" "Mood Journal" "Appointment Journal" "Exit")
				case $MAIN_CHOICE in
					"Exit")
					PROG_LOOP=0
				esac
				case $MAIN_CHOICE in
					"Med Logs")
					SUB_CHOICE=$(gum choose "View Med Log" "Add Med" "Clear Med Log")
					case $SUB_CHOICE in
						"View Med Log")
						while read -r LINE
						do
							echo "${LINE}"
						done < "${SAVE_DIR}/medLog.txt"
						echo ""
					esac
					case $SUB_CHOICE in
						"Add Med")
						REGEX='^[0-9]+$'
						read -p "How many medications would you like to enter? " LEN
						if ! [[ $LEN =~ $REGEX ]]; then
							drawTextErr "ERR: Not a number"
							exit 1
						fi
						drawTextStd "Enter the following info to record your medications."
						recordMedications $LEN
					esac
					case $SUB_CHOICE in
						"Clear Med Log")
						gum confirm "Are you sure you want to clear the medication log? This action cannot be undone." && drawTextErr "Clearing medication log..." && > "${SAVE_DIR}/medLog.txt" || drawTextStd "Returning to menu..."
					esac
				esac
				case $MAIN_CHOICE in
					"Mood Journal")
					SUB_CHOICE=$(gum choose "Add Journal Entry" "View Journal Entry" "Clear Journal")
					case $SUB_CHOICE in
						"Add Journal Entry")
						drawTextStd "Checking for journal..."
						if ! [[ -d "${SAVE_DIR}/journal" ]]; then
							drawTextStd "No journal found..."
							drawTextStd "Building journal..."
							mkdir "${SAVE_DIR}/journal"
							if [[ $? -ne 0 ]]; then
								drawTextErr "ERR: Failed to build journal. Maybe there is an error in your config?"
							else
								addJournalEntry
							fi
						else
							addJournalEntry
						fi
					esac
					case $SUB_CHOICE in
						"View Journal Entry")
						drawTextStd "Checking for journal..."
						if ! [[ -d "${SAVE_DIR}/journal" ]]; then
							drawTextStd "No journal found..."
						else
							drawTextStd "Opening journal..."
							SEL_ENTRY=$(gum file "${SAVE_DIR}/journal")
							cat $SEL_ENTRY
						fi
					esac
					case $SUB_CHOICE in
						"Clear Journal")
						drawTextStd "Checking for journal..."
						if ! [[ -d "${SAVE_DIR}/journal" ]]; then
							drawTextStd "No journal found..."
						else
							gum confirm && drawTextErr "Clearing journal..." && rm -rf "${SAVE_DIR}/journal" && drawTextErr "Journal cleared!" || drawTextStd "Returning to menu..."
						fi
					esac
				esac
				case $MAIN_CHOICE in
					"Appointment Journal")
					SUB_CHOICE=$(gum choose "Add Appointment" "View Journal Entry" "Clear Appointment Journal")
					case $SUB_CHOICE in
						"Add Appointment")
						drawTextStd "Checking for journal..."
						if ! [[ -d "${SAVE_DIR}/appt_journal" ]]; then
							drawTextStd "No journal found..."
							drawTextStd "Building journal..."
							mkdir "${SAVE_DIR}/appt_journal"
							if [[ $? -ne 0 ]]; then
								drawTextErr "ERR: Failed to build journal. Maybe there is an error in your config?"
							else
								addJournalEntry_Appt
							fi
						else
							addJournalEntry_Appt
						fi
					esac
					case $SUB_CHOICE in
						"View Journal Entry")
						drawTextStd "Checking for journal..."
						if ! [[ -d "${SAVE_DIR}/appt_journal" ]]; then
							drawTextStd "No journal found..."
						else
							drawTextStd "Opening journal..."
							SEL_ENTRY=$(gum file "${SAVE_DIR}/appt_journal")
							cat $SEL_ENTRY
						fi
					esac
					case $SUB_CHOICE in
						"Clear Appointment Journal")
						drawTextStd "Checking for journal..."
						if ! [[ -d "${SAVE_DIR}/appt_journal" ]]; then
							drawTextStd "No journal found..."
						else
							gum confirm && drawTextErr "Clearing journal..." && rm -rf "${SAVE_DIR}/appt_journal" && drawTextErr "Journal cleared!" || drawTextStd "Returning to menu..."
						fi
					esac
				esac

			else
				drawTextErr "ERR: That directory doesn't exist."
				exit 1
			fi
	fi						
	done	



