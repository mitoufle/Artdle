extends Node
class_name GameLogger

## Système de logging centralisé pour remplacer les print statements
## Permet de contrôler le niveau de log et de formater les messages

#==============================================================================
# Log Levels
#==============================================================================
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3
}

#==============================================================================
# Configuration
#==============================================================================
var current_log_level: LogLevel = LogLevel.INFO
var enable_console_output: bool = true
var enable_file_output: bool = false
var log_file_path: String = "user://game_log.txt"

#==============================================================================
# Public API
#==============================================================================

## Log un message de debug
func debug(message: String, context: String = "") -> void:
	_log(LogLevel.DEBUG, message, context)

## Log un message d'information
func info(message: String, context: String = "") -> void:
	_log(LogLevel.INFO, message, context)

## Log un message d'avertissement
func warning(message: String, context: String = "") -> void:
	_log(LogLevel.WARNING, message, context)

## Log un message d'erreur
func error(message: String, context: String = "") -> void:
	_log(LogLevel.ERROR, message, context)

## Définit le niveau de log minimum
func set_log_level(level: LogLevel) -> void:
	current_log_level = level

## Active ou désactive la sortie console
func set_console_output(enabled: bool) -> void:
	enable_console_output = enabled

## Active ou désactive la sortie fichier
func set_file_output(enabled: bool) -> void:
	enable_file_output = enabled

#==============================================================================
# Private Methods
#==============================================================================

func _log(level: LogLevel, message: String, context: String = "") -> void:
	if level < current_log_level:
		return
	
	var timestamp = Time.get_datetime_string_from_system()
	var level_name = LogLevel.keys()[level]
	var context_str = " [%s]" % context if context != "" else ""
	var formatted_message = "[%s] %s%s: %s" % [timestamp, level_name, context_str, message]
	
	if enable_console_output:
		match level:
			LogLevel.DEBUG:
				print_rich("[color=gray]%s[/color]" % formatted_message)
			LogLevel.INFO:
				print(formatted_message)
			LogLevel.WARNING:
				print_rich("[color=yellow]%s[/color]" % formatted_message)
			LogLevel.ERROR:
				print_rich("[color=red]%s[/color]" % formatted_message)
	
	if enable_file_output:
		_write_to_file(formatted_message)

func _write_to_file(message: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.WRITE_READ)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()
	else:
		push_error("Failed to open log file: %s" % log_file_path)
