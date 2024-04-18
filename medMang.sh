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
drawTextStd "Welcome to the Linux Medication Management TUI tool."
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
			for ((i=0; i < $LEN; i++))
			do
				read -p "Name of Medication: " MED_NAME
				read -p "Date of Expiration (MM/YYYY): " MED_EXP
				read -p "Dosage Amount (include units): " MED_DOSE
				read -p "Refills Left: " MED_REFILLS
				read -p "Next Refill (MM/YYYY): " MED_NEXT
				echo "Medication: ${MED_NAME} || Exp: ${MED_EXP} | Dosage: ${MED_DOSE} | Refills: ${MED_REFILLS} | Next Refill: ${MED_NEXT}" >> "${SAVE_DIR}/medMang/medLog.txt"
			done
		fi
	fi				
	if [[ $INIT_CONFIG -ne 0 ]]; then
		drawTextStd "Awesome, where are your files stored?"
			echo "Checking ${SAVE_DIR} for files..."
			if [[ -d "${SAVE_DIR}" ]]; then
				drawTextStd "Files loaded! What are you looking for today?"
				MAIN_CHOICE=$(gum choose "Med Logs" "Mood Journal" "Appt Logs" "Exit")
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
						for ((i=0; i < $LEN; i++))
						do
							read -p "Name of Medication: " MED_NAME
							read -p "Date of Expiration (MM/YYYY): " MED_EXP
							read -p "Dosage Amount (include units): " MED_DOSE
							read -p "Refills Left: " MED_REFILLS
							read -p "Next Refill (MM/YYYY): " MED_NEXT
							echo "Medication: ${MED_NAME} || Exp: ${MED_EXP} | Dosage: ${MED_DOSE} | Refills: ${MED_REFILLS} | Next Refill: ${MED_NEXT}" >> "${SAVE_DIR}/medLog.txt"
						done
					esac
					case $SUB_CHOICE in
						"Clear Med Log")
						CONFIRM=$(gum confirm -v "Are you sure you want to clear the medication log? This action cannot be undone.")
						echo $CONFIRM
						drawTextErr "Clearing medication log..."
						> "${SAVE_DIR}/medLog.txt"
					esac
				esac
			else
				drawTextErr "ERR: That directory doesn't exist."
				exit 1
			fi
	fi						
	done	



