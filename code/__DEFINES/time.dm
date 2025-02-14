#define MIDNIGHT_ROLLOVER		864000	//number of deciseconds in a day

#define JANUARY		1
#define FEBRUARY	2
#define MARCH		3
#define APRIL		4
#define MAY			5
#define JUNE		6
#define JULY		7
#define AUGUST		8
#define SEPTEMBER	9
#define OCTOBER		10
#define NOVEMBER	11
#define DECEMBER	12

//Select holiday names -- If you test for a holiday in the code, make the holiday's name a define and test for that instead
#define NEW_YEAR				"Новогодний Сектор |"
#define VALENTINES				"День Святого Валентина |"
#define APRIL_FOOLS				"День дурака |"
#define EASTER					"Пасха |"
#define PRIDE_MONTH				"Гейский День Гейских Геев |"
#define HALLOWEEN				"Хэллоуин |"
#define CHRISTMAS				"Рождество |"
#define FESTIVE_SEASON			"Праздничный сезон |"
#define GARBAGEDAY				"Мусорный День |"
#define MONKEYDAY				"День Обезьяны |"
/*

Days of the week to make it easier to reference them.

When using time2text(), please use "DDD" to find the weekday. Refrain from using "Day"

*/

#define MONDAY		"Mon"
#define TUESDAY		"Tue"
#define WEDNESDAY	"Wed"
#define THURSDAY	"Thu"
#define FRIDAY		"Fri"
#define SATURDAY	"Sat"
#define SUNDAY		"Sun"

#define WEEKDAY2NUM(D) (D == SUNDAY ? 1 : D == MONDAY ? 2 : D == TUESDAY ? 3 : D == WEDNESDAY ? 4 : D == THURSDAY ? 5 : D == FRIDAY ? 6 : 7) //this looks ugly, but switch statements can't be used as vars, so *shrug

#define SECONDS *10

#define MINUTES SECONDS*60

#define HOURS MINUTES*60

#define TICKS *world.tick_lag

#define DECISECONDS *1

#define MILLISECONDS * 0.01

#define DS2TICKS(DS) ((DS)/world.tick_lag)

#define TICKS2DS(T) ((T) TICKS)

#define MS2DS(T) ((T) MILLISECONDS)

#define DS2MS(T) ((T) * 100)

#define GAMETIMESTAMP(format, wtime) time2text(wtime, format)
#define WORLDTIME2TEXT(format) GAMETIMESTAMP(format, world.time)
#define WORLDTIMEOFDAY2TEXT(format) GAMETIMESTAMP(format, world.timeofday)
#define TIME_STAMP(format, showds) showds ? "[WORLDTIMEOFDAY2TEXT(format)]:[world.timeofday % 10]" : WORLDTIMEOFDAY2TEXT(format)
// WAS - #define STATION_TIME(display_only, wtime) ((((wtime - SSticker.round_start_time) * SSticker.station_time_rate_multiplier) + SSticker.gametime_offset) % 864000) - (display_only? GLOB.timezoneOffset : 0)
//BLUEMOON CHANGE END
//BLUEMOON CHANGE START
#define STATION_TIME(display_only, wtime) (((wtime - SSticker.round_start_time) + SSticker.gametime_offset) % 864000) - (display_only? GLOB.timezoneOffset : 0)
#define STATION_TIME_TIMESTAMP(format, wtime) time2text(STATION_TIME(TRUE, wtime), format)

#define ROUND_TIME(...) ( "[world.time - SSticker.round_start_time > MIDNIGHT_ROLLOVER ? "[round((world.time - SSticker.round_start_time)/MIDNIGHT_ROLLOVER)]:[worldtime2text()]" : worldtime2text()]" )
