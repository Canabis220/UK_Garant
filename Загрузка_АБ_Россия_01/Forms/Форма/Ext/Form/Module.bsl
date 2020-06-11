﻿
//Глобальные переменные

#Область ГлобальныеПеременные

&НаКлиенте
Перем 
	Глоб_МассивСтруктур,
	Глоб_РазделительПути,
	Глоб_РазделительПолей;

&НаСервере
Перем  
	Глоб_ИндексНомерЛС,
	Глоб_ИндексФИО,
	Глоб_ИндексСуммаОплаты,
	Глоб_ИндексДатаОплаты,
	Глоб_ПозицияБлокаСчетчиков,
	Глоб_РазделительПути,
	Глоб_РазделительПолей,
	Глоб_РазделительСчетчиков,
	Глоб_РазделительКодовВНаименованииСчетчика;
#КонецОбласти

//Выгрузка

#Область Выгрузка

&НаКлиенте
Процедура ПериодПриИзменении(Элемент)
  ПериодВыгрузки = КонецМесяца(ПериодВыгрузки);
КонецПроцедуры

&НаКлиенте
Процедура ПутьВыгрузкиНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)

	Режим = РежимДиалогаВыбораФайла.ВыборКаталога;
	ДиалогОткрытияФайла = Новый ДиалогВыбораФайла(Режим);
	ДиалогОткрытияФайла.ПолноеИмяФайла = "";
	ДиалогОткрытияФайла.Заголовок = "Выберите каталог для файлов выгрузки";
	Если ДиалогОткрытияФайла.Выбрать() Тогда
		ПутьВыгрузки=ДиалогОткрытияФайла.Каталог;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьВыгрузку(Команда)
	
	Адрес = СформироватьВыгрузкуНаСервере(ПериодВыгрузки);
	ИмяРеестра = ПолучитьИмяРеестраНаСервере(Организация, РасчетныйСчет, Код);
	ПолныйПуть = ПутьВыгрузки + Глоб_РазделительПути + ИмяРеестра + ".rkp";
			
	ПолучитьИзВременногоХранилища(Адрес).Записать(ПолныйПуть);
	УдалитьИзВременногоХранилища(Адрес);
	
	ОчиститьСообщения();
	Сообщить("Файл выгрузки сформирован!");	
	
КонецПроцедуры

&НаСервереБезКонтекста
Функция ПолучитьИмяРеестраНаСервере(СсылкаНаОрганизацию, СсылкаНаРасчетныйСчет, СсылкаНаКод)
	ИмяРеестра = СсылкаНаОрганизацию.ИНН + "_" + СсылкаНаРасчетныйСчет.НомерСчета + "_" + СсылкаНаКод + "_" + Формат(Дата(ТекущаяДата()), "ДФ=MMdd");
	Возврат ИмяРеестра;
КонецФункции

&НаСервере
Функция СформироватьВыгрузкуНаСервере(Период)
	
	ЗапросПоЗадолжености = Новый Запрос("ВЫБРАТЬ
	                                    |	ркЛицевыеСчета.Код КАК НомерЛС,
	                                    |	ркЛицевыеСчета.Ссылка КАК ЛицевойСчет,
	                                    |	ЕСТЬNULL(ркЛицевыеСчета.Дом.Владелец.Город.Наименование, """") КАК Город,
	                                    |	ЕСТЬNULL(ркЛицевыеСчета.Дом.Владелец.НаселенныйПункт.Наименование, """") КАК НаселенныйПункт,
	                                    |	ркЛицевыеСчета.Дом.Владелец.Наименование КАК Улица,
	                                    |	ркЛицевыеСчета.Дом КАК СсылкаНаДом,
	                                    |	ркЛицевыеСчета.Дом.Номер КАК Дом,
	                                    |	ркЛицевыеСчета.Дом.Корпус КАК Корпус,
	                                    |	ркЛицевыеСчета.Помещение.Номер КАК Квартира,
	                                    |	ЕСТЬNULL(ркЗадолженностьЛицевыхСчетовОстатки.СуммаОстаток, 0) КАК Сумма
	                                    |ИЗ
	                                    |	Справочник.ркЛицевыеСчета КАК ркЛицевыеСчета
	                                    |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ркЗадолженностьЛицевыхСчетов.Остатки(&Период, ) КАК ркЗадолженностьЛицевыхСчетовОстатки
	                                    |		ПО (ркЗадолженностьЛицевыхСчетовОстатки.ЛицевойСчет = ркЛицевыеСчета.Ссылка)
	                                    |ГДЕ
	                                    |	ркЛицевыеСчета.ЭтоГруппа = ЛОЖЬ
	                                    |	И ркЛицевыеСчета.ПометкаУдаления = ЛОЖЬ
	                                    |	И (ркЛицевыеСчета.ДатаЗакрытия = &ПустаяДата
	                                    |			ИЛИ ркЛицевыеСчета.ДатаЗакрытия > &ДатаЗакрытияЛС)
	                                    |
	                                    |УПОРЯДОЧИТЬ ПО
	                                    |	НомерЛС
	                                    |ИТОГИ
	                                    |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ ЛицевойСчет),
	                                    |	СУММА(Сумма)
	                                    |ПО
	                                    |	ОБЩИЕ");
	
	
	ЗапросПоЗадолжености.УстановитьПараметр("ПустаяДата", Дата(1,1,1));
	ЗапросПоЗадолжености.УстановитьПараметр("Период", Новый Граница(КонецМесяца(Период)));
	ЗапросПоЗадолжености.УстановитьПараметр("ДатаЗакрытияЛС", (КонецМесяца(Период)));
	//ЗапросПоЗадолжености.УстановитьПараметр("Участки", Участки);
	
	ЗапросСчетчики = Новый Запрос("ВЫБРАТЬ
	                              |	ркЛицевыеСчета.Ссылка КАК ЛицевойСчет,
	                              |	ркЛицевыеСчета.Помещение.Код КАК КодПомещения,
	                              |	ркЛицевыеСчета.Помещение КАК Помещение,
	                              |	ркСчетчики.Код КАК КодСчетчика,
	                              |	ркСчетчики.Ссылка КАК Счетчик,
	                              |	ркСостояниеСчетчиковСрезПоследних.Включен КАК Включен
	                              |ИЗ
	                              |	Справочник.ркЛицевыеСчета КАК ркЛицевыеСчета
	                              |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.ркСчетчики КАК ркСчетчики
	                              |			ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ркСостояниеСчетчиков.СрезПоследних(&ПериодСчетчиков, ) КАК ркСостояниеСчетчиковСрезПоследних
	                              |			ПО ркСчетчики.Ссылка = ркСостояниеСчетчиковСрезПоследних.Счетчик
	                              |		ПО ркЛицевыеСчета.Помещение = ркСчетчики.Владелец
	                              |ГДЕ
	                              |	ркСостояниеСчетчиковСрезПоследних.Счетчик.Групповой = ЛОЖЬ
	                              |	И ркСостояниеСчетчиковСрезПоследних.Включен = ИСТИНА
								  |
	                              |УПОРЯДОЧИТЬ ПО
	                              |	ркЛицевыеСчета.Наименование");

	ЗапросСчетчики.УстановитьПараметр("ПериодСчетчиков", КонецМесяца(Период));
	//ЗапросСчетчики.УстановитьПараметр("Участки", Участки);
	ТаблСчетчиков = ЗапросСчетчики.Выполнить().Выгрузить();
	ТаблСчетчиков.Индексы.Добавить("ЛицевойСчет");
	
	
	
	РезультатЗапросаПоЗадолженостиИтоги = ЗапросПоЗадолжености.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	
	РезультатЗапросаПоЗадолженостиИтоги.Следующий();
	КоличествоЗаписей = РезультатЗапросаПоЗадолженостиИтоги.ЛицевойСчет;
	ОбщаяСуммаЗадолженности = Формат(РезультатЗапросаПоЗадолженостиИтоги.Сумма, "ЧДЦ=2; ЧРД=.; ЧН=; ЧГ=3,0");
	
	РезультатЗапросаПоЗадолжености = РезультатЗапросаПоЗадолженостиИтоги.Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	
	Если РезультатЗапросаПоЗадолжености.Количество() = 0 Тогда 
		Сообщить("Нет данных для выгрузки!");
		Адрес = Неопределено;
	Иначе 	
				
		ИмяВременногоФайла = ПолучитьИмяВременногоФайла();
		Текст = Новый ЗаписьТекста(ИмяВременногоФайла, КодировкаТекста.ANSI);
		
		СтруктураЛицевойСчет = Новый Структура;
		
		Пока РезультатЗапросаПоЗадолжености.Следующий() Цикл	
			
			СтруктураЛицевойСчет.Вставить("ЛицевойСчет", РезультатЗапросаПоЗадолжености.ЛицевойСчет);
			СтрокаСчетчиков = "";
			
			///Счетчики
			
			Если ВыгружатьСчетчики Тогда 
				
				СчетчикиЛицСчета = ТаблСчетчиков.НайтиСтроки(СтруктураЛицевойСчет);
				
				Для Каждого СсылкаСчетчик Из СчетчикиЛицСчета Цикл
					
					Для Каждого СтрВидыПоказаний Из  СсылкаСчетчик.Счетчик.ВидыПоказаний Цикл
						
						Попытка
							ПоказанияСчетчика = Формат(
							Число(Документы.ркПоказанияСчетчиков.ПолучитьНачальныеПоказанияПоПриборуУчета(СсылкаСчетчик.Счетчик, СтрВидыПоказаний.ВидПоказаний)),
							"ЧДЦ=0; ЧРД=.; ЧН=; ЧГ=0"
							);
						Исключение
							ПоказанияСчетчика = Формат(0, "ЧДЦ=0; ЧРД=.; ЧН=; ЧГ=0");
						КонецПопытки;
						
						СтрокаСчетчиков = 
						СтрокаСчетчиков +
						Прав(СокрЛП(Строка(СтрВидыПоказаний.ВидПоказаний.Код)), 2) + Глоб_РазделительКодовВНаименованииСчетчика +
						Строка(СсылкаСчетчик.Счетчик) + Глоб_РазделительСчетчиков +
						ПоказанияСчетчика + Глоб_РазделительСчетчиков
						;
						
					КонецЦикла;
					
				КонецЦикла;
				
				СтрокаСчетчиков = Лев(СтрокаСчетчиков, СтрДлина(СтрокаСчетчиков)-1);
				
			КонецЕсли;
			
			///
			
			НомерЛС = Строка(СокрЛП(РезультатЗапросаПоЗадолжености.НомерЛС));
			
			ЛицевойСчет = Строка(СокрЛП(РезультатЗапросаПоЗадолжености.ЛицевойСчет));
			Адрес = Строка(СформироватьСтрокуАдреса(РезультатЗапросаПоЗадолжености));
			ПериодОплаты = Формат(ПериодВыгрузки, "ДФ=MMyy");
			СуммаЗадолжности = Строка(Формат(РезультатЗапросаПоЗадолжености.Сумма, "ЧДЦ=2; ЧРД=.; ЧН=; ЧГ=0"));
			
			СтрокаЗаписи = 
				НомерЛС + Глоб_РазделительПолей +
				ЛицевойСчет + Глоб_РазделительПолей +
				Адрес + Глоб_РазделительПолей +
				ПериодОплаты + Глоб_РазделительПолей +
				СуммаЗадолжности + Глоб_РазделительПолей + 
				СтрокаСчетчиков 
			;
				
			Текст.ЗаписатьСтроку(СтрокаЗаписи);			
		КонецЦикла;
		
		Текст.Закрыть();
		
		Данные = Новый ДвоичныеДанные(ИмяВременногоФайла);
		Адрес = ПоместитьВоВременноеХранилище(Данные, УникальныйИдентификатор);
		
	КонецЕсли;	

	Возврат Адрес;
	
КонецФункции

&НаСервере
Процедура ПриСозданииНаСервере(Отказ)
	ПериодВыгрузки = ркОбщегоНазначенияСервер.ПолучитьДатуОкончанияТекущегоРасчетногоПериода();
КонецПроцедуры

функция СформироватьСтрокуАдреса(СтрРезЗапроса)
	
	Город = ? (СтрРезЗапроса.Город <> "", СтрРезЗапроса.Город + " г, ", "");
	НаселенныйПункт = ? (СтрРезЗапроса.НаселенныйПункт <> "", СтрРезЗапроса.НаселенныйПункт + ", ", "");
	Улица = ? (Строка(СтрРезЗапроса.Улица) <> "", "ул."+строка(СтрРезЗапроса.Улица) + ", ", "");
	Дом = "д." + СтрРезЗапроса.Дом;
	Корпус = ? (СтрРезЗапроса.Корпус <> "", "/" + СтрРезЗапроса.Корпус, "");
	Квартира = ? (СтрРезЗапроса.Квартира <> "", ", кв." + СтрРезЗапроса.Квартира, "");
	
	Адрес = Город+НаселенныйПункт+Улица+Дом+Корпус+Квартира;
	
	Возврат Адрес;
	
КонецФункции

Функция ПолучитьПорядковыйНомерФайлаВДень()
	
	УникальныйИдентификаторЗначения = "0e1b51a56f674d65c31e2b1d5bb772bс";
	
	ПорядковыйНомерФайла = ркОбщегоНазначенияСервер.ПрочитатьЗначение(УникальныйИдентификаторЗначения,"ПорядковыйНомерФайла");
	Если ПорядковыйНомерФайла <> Неопределено Тогда
		ПорядковыйНомерФайла = ПорядковыйНомерФайла + 1;
		Если ПорядковыйНомерФайла = 1000 Тогда
			ПорядковыйНомерФайла = 1;	
		КонецЕсли;	
		ркОбщегоНазначенияСервер.ЗаписатьЗначение(УникальныйИдентификаторЗначения,"ПорядковыйНомерФайла", ПорядковыйНомерФайла);
	ИначеЕсли ПорядковыйНомерФайла = Неопределено Тогда
		ПорядковыйНомерФайла = 1;
		ркОбщегоНазначенияСервер.ЗаписатьЗначение(УникальныйИдентификаторЗначения,"ПорядковыйНомерФайла", ПорядковыйНомерФайла);	
	КонецЕсли;
	
	Возврат формат(ПорядковыйНомерФайла,"ЧЦ=3; ЧВН=");
	
КонецФункции

#КонецОбласти

//Загрузка

#Область Загрузка

&НаКлиенте
Процедура ПутьЗагрузкиНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	
	Режим = РежимДиалогаВыбораФайла.ВыборКаталога;
	ДиалогОткрытияФайла = Новый ДиалогВыбораФайла(Режим);
	ДиалогОткрытияФайла.ПолноеИмяФайла = "";
	ДиалогОткрытияФайла.Заголовок = "Выберите каталог для файлов загрузки";
	Если ДиалогОткрытияФайла.Выбрать() Тогда
		ПутьЗагрузки = ДиалогОткрытияФайла.Каталог;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ОбновитьСписок(Команда)
	
	ОчиститьСообщения();
	Файлы.Очистить();
	Глоб_МассивСтруктур = Новый Массив;	
	
	МассивФайлов = НайтиФайлы(ПутьЗагрузки, "*.rk1*");
	
	Для Каждого Файл Из МассивФайлов Цикл
		//Попытка
			ДанныеИзФайла = ПолучитьДанныеИзФайла(Файл.ПолноеИмя);
			//сообщить(Файл.ПолноеИмя);
			СтруктураРеестр = Новый Структура;
			СтруктураРеестр.Вставить("Имя",Файл.Имя);
			СтруктураРеестр.Вставить("Хэш",Строка(ПолучитьХэшФайла(Новый ДвоичныеДанные(Файл.ПолноеИмя))));
			СтруктураРеестр.Вставить("Содержание",ДанныеИзФайла);
			СтруктураРеестр.Вставить("Путь",Файл.ПолноеИмя);			
			ОплатыИСчетчикиРеестра = ЗаполнитьТаблицуФайлов(Файл.Имя, ДанныеИзФайла);

			СтруктураРеестр.Вставить("Оплаты",ОплатыИСчетчикиРеестра.Оплаты);
			СтруктураРеестр.Вставить("Счетчики",ОплатыИСчетчикиРеестра.Счетчики);
			Глоб_МассивСтруктур.Добавить(СтруктураРеестр);
		//Исключение
			//Сообщить("Ошибка формата файла: " + Файл.Имя);
		//КонецПопытки;
	КонецЦикла;
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьЗагрузку(Команда)
	ОчиститьСообщения();
	Если Файлы.Количество() = 0 Тогда
		Сообщить("Необходимо заполнить таблицу загружаемых реестров. Загрузка не выполнена");
		Возврат;
	КонецЕсли;
	
	РезультатЗагрузки = ВыполнитьЗагрузкуНаСервере(Глоб_МассивСтруктур);
	Для Каждого Реестр Из РезультатЗагрузки Цикл 
		
		Если Реестр.КоличествоЗагруженныхОплат > 0 И Реестр.КоличествоЗагруженныхСчетчиков > 0 Тогда
			 СоздатьКаталог(ПутьЗагрузки+Глоб_РазделительПути+"Загруженные реестры");
			 ПереместитьФайл(Реестр.Путь, ПутьЗагрузки+Глоб_РазделительПути+"Загруженные реестры"+Глоб_РазделительПути+Реестр.Имя);
			 ОбновитьСписок(Команда);
		КонецЕсли;
		Сообщить("Загружено оплат "+Строка(Реестр.КоличествоЗагруженныхОплат)+"/"+Реестр.ОплатВРеестре+" из реестра: "+Реестр.Имя);
		Если (Реестр.СчетчиковВРеестре>0) Тогда
			Сообщить("Загружено счетчиков "+Строка(Реестр.КоличествоЗагруженныхСчетчиков)+"/"+Реестр.СчетчиковВРеестре+" из реестра: "+Реестр.Имя);
		КонецЕсли;
	КонецЦикла;	
	
	Если ЖурналОшибок.Количество() <> 0 Тогда
		Ошибки = ПолучитьОтчетЖурналОшибок();
		Ошибки.Показать();
		СоздатьКаталог(ПутьЗагрузки+Глоб_РазделительПути+"Журналы ошибок");
		ИмяФайла = ПутьЗагрузки+Глоб_РазделительПути+"Журналы ошибок"+Глоб_РазделительПути+"Журнал_" + Формат(ТекущаяДата(), "ДФ=yyyy-MM-dd_HHmm") + ".mxl";
		Ошибки.Записать(ИмяФайла);
		ЖурналОшибок.Очистить();
	КонецЕсли;
КонецПроцедуры

&НаСервере
Функция ВыполнитьЗагрузкуНаСервере(Реестры)	
	
	РезультатЗагрузки = Новый Массив;
	
	Для Каждого Реестр Из Реестры Цикл		
		
		ДатаФормирования = ПолучитьДатуФормированияРеестраИзИмени(Реестр.Имя);
		ИдентификаторРеестра = Реестр.Хэш;
		
		ДанныеДляЗагрузкиОплаты = Новый ТаблицаЗначений;
		ДанныеДляЗагрузкиОплаты.Колонки.Добавить("СтрокаРеестра");
		
		ДанныеДляЗагрузкиСчетчиков = Новый ТаблицаЗначений;
		ДанныеДляЗагрузкиСчетчиков.Колонки.Добавить("СтрокаРеестра");
		
		Для Каждого МассивИзСтрокиРеестра Из Реестр.Содержание Цикл
			Если ПолучитьКоличествоСчетчиковВСтроке(МассивИзСтрокиРеестра, Глоб_ПозицияБлокаСчетчиков - 1) > 0 Тогда
				СтрокаДанныхОплата = ДанныеДляЗагрузкиОплаты.Добавить();
				СтрокаДанныхОплата.СтрокаРеестра = МассивИзСтрокиРеестра;
				СтрокаДанныхСчетчики = ДанныеДляЗагрузкиСчетчиков.Добавить();
				СтрокаДанныхСчетчики.СтрокаРеестра = МассивИзСтрокиРеестра;				
			Иначе
				СтрокаДанныхОплата = ДанныеДляЗагрузкиОплаты.Добавить();
				СтрокаДанныхОплата.СтрокаРеестра = МассивИзСтрокиРеестра;
			КонецЕсли;			
		КонецЦикла;
		
		РезультатЗагрузкиРеестра = Новый Структура;
		КоличествоЗагруженныхОплат = ЗагрузитьОплату(Реестр.Имя, ДатаФормирования, ИдентификаторРеестра, ДанныеДляЗагрузкиОплаты);
		КоличествоЗагруженныхСчетчиков = ЗагрузитьСчетчики(Реестр.Имя, ДатаФормирования, ИдентификаторРеестра, ДанныеДляЗагрузкиСчетчиков);
		РезультатЗагрузкиРеестра.Вставить("Имя", Реестр.Имя);
		РезультатЗагрузкиРеестра.Вставить("Путь", Реестр.Путь);
		РезультатЗагрузкиРеестра.Вставить("ОплатВРеестре", Реестр.Оплаты);
		РезультатЗагрузкиРеестра.Вставить("СчетчиковВРеестре", Реестр.Счетчики);
		РезультатЗагрузкиРеестра.Вставить("КоличествоЗагруженныхОплат", КоличествоЗагруженныхОплат);
		РезультатЗагрузкиРеестра.Вставить("КоличествоЗагруженныхСчетчиков", КоличествоЗагруженныхСчетчиков);
		РезультатЗагрузки.Добавить(РезультатЗагрузкиРеестра);
		
	КонецЦикла;
	
	Возврат РезультатЗагрузки;
	
КонецФункции

Функция ПолучитьДатуФормированияРеестраИзИмени(ИмяРеестра)
	
	Возврат ФорматироватьДату("2020"+Сред(ИмяРеестра,7,2)+Сред(ИмяРеестра,5,2), Ложь);
	
КонецФункции

Функция ФорматироватьДату(СтрДата, ЕстьРазделитель = Истина)
	
	Если ЕстьРазделитель Тогда 
		НачальныйНомерМесяца = 4;
		НачальныйНомерГода = 7;
	Иначе 
		НачальныйНомерМесяца = 5;
		НачальныйНомерГода = 1;
	КонецЕсли;
	
	День = Число(Прав(СтрДата, 2));
	Месяц = Число(Сред(СтрДата, НачальныйНомерМесяца, 2));
	Год = Число(Сред(СтрДата, НачальныйНомерГода, 4));	
	Дата = Дата(Год, Месяц, День);
	
	Возврат Дата;
	
КонецФункции

Функция ЗаменитьПустыеЭлементы(Массив)
	
	Для  ИндексЭлемента = 0 По Массив.Количество() - 1 Цикл 
		Если Массив[ИндексЭлемента] = "" Тогда 
			Массив[ИндексЭлемента] = 0;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Массив;
	
КонецФункции

&НаКлиенте
Функция ПолучитьДанныеИзФайла(ПутьКФайлу)
	
	МассивСтрокРеестра = Новый Массив;
	
	ТекстРеестра = Новый ЧтениеТекста(ПутьКФайлу, КодировкаТекста.OEM);
	СтрокаРеестра = "";
	
	Пока СтрокаРеестра <> Неопределено  Цикл 
		СтрокаРеестра = ТекстРеестра.ПрочитатьСтроку();

		Если Лев(СтрокаРеестра, 1) <>"|" Тогда	
			Продолжить;
		КонецЕсли;
		
		МассивПолей = СтрРазделить(СтрокаРеестра, Глоб_РазделительПолей);
		МассивСтрокРеестра.Добавить(МассивПолей);
			КонецЦикла;
	
	Возврат МассивСтрокРеестра;
	
КонецФункции

&НаСервере
Функция ЗаполнитьТаблицуФайлов(ИмяРеестра, Данные)
	
	ДатаФормированияРеестра = ПолучитьДатуФормированияРеестраИзИмени(ИмяРеестра);
	ОплатВРеестре = 0;
	СчетчиковВРеестре = 0;
	Сумма = 0;

Для Каждого Строка Из Данные Цикл 
		Сумма = Сумма + Число(Строка[Глоб_ИндексСуммаОплаты - 1])/100;
		ОплатВРеестре = ОплатВРеестре + 1;
//		СчетчиковВРеестре = СчетчиковВРеестре + ПолучитьКоличествоСчетчиковВСтроке(Строка, Глоб_ПозицияБлокаСчетчиков - 1);
		СчетчиковВРеестре = 0;
	КонецЦикла;
	
	ОплатыИСчетчикиРеестра = Новый Структура;
	ОплатыИСчетчикиРеестра.Вставить("Оплаты",ОплатВРеестре);
	ОплатыИСчетчикиРеестра.Вставить("Счетчики",СчетчиковВРеестре);
	
	Стр = Файлы.Добавить();
	Стр.Дата = ДатаФормированияРеестра;
	Стр.Реестр = ИмяРеестра;
	Стр.ОплатВРеестре = ОплатВРеестре;
	Стр.СчетчиковВРеестре = СчетчиковВРеестре;
	Стр.Сумма = Сумма;
	
	Возврат ОплатыИСчетчикиРеестра;
	
КонецФункции

&НаСервере                  
Функция ПолучитьКоличествоСчетчиковВСтроке(МассивПолей, ПозицияБлокаСчетчиков, РазделительОбщий = Истина)
	
	СчетчикиВСроке = Новый Массив;
	
	Если РазделительОбщий Тогда 
		Для i = ПозицияБлокаСчетчиков По МассивПолей.Количество() - 1 Цикл 
			СчетчикиВСроке.Добавить(МассивПолей[i]);
		КонецЦикла;
	Иначе	
		СчетчикиВСроке = СтрРазделить(МассивПолей[ПозицияБлокаСчетчиков], Глоб_РазделительСчетчиков);
	КонецЕсли;
	
	Возврат Окр(СчетчикиВСроке.Количество()/2);
	
КонецФункции	

&НаСервере
Функция ПолучитьХэшФайла(ДанныеФайла)
	ХешированиеДанных = Новый ХешированиеДанных(ХешФункция.SHA1);
	ХешированиеДанных.Добавить(ДанныеФайла);
	Возврат ХешированиеДанных.ХешСумма;
КонецФункции
	
Функция ЗагрузитьОплату(ИмяРеестра, ДатаФормирования, ИдентификаторРеестра, ДанныеДляЗагрузкиОплаты)
	КоличествоЗагруженныхОплат = 0;		
	
	Документ = Новый Запрос("ВЫБРАТЬ ПЕРВЫЕ 1
	                        |	ркОплата.Ссылка КАК Док
	                        |ИЗ
	                        |	Документ.ркОплата КАК ркОплата
	                        |ГДЕ
	                        |	ркОплата.ИдентификаторРеестра = &ИдентификаторРеестра
	                        |	И ркОплата.ПометкаУдаления = ЛОЖЬ
	                        |
	                        |СГРУППИРОВАТЬ ПО
	                        |	ркОплата.Ссылка");
	Документ.УстановитьПараметр("ИдентификаторРеестра", ИдентификаторРеестра);
	РезультатыЗапросаДокумент = Документ.Выполнить().Выбрать();
	
	Если РезультатыЗапросаДокумент.Следующий() Тогда		
		Сообщить("Оплата из реестра "+ ИмяРеестра + " уже загружена в документ "+РезультатыЗапросаДокумент.Док);
		// Реестр уже загружен
	Иначе 
		Документ = Документы.ркОплата.СоздатьДокумент();
		Документ.ИдентификаторРеестра = ИдентификаторРеестра;
		Документ.Заполнить(Неопределено);
		Документ.Комментарий = "Данные загружены из реестра::" + ИмяРеестра;
		Документ.Дата = Макс(ДатаФормирования, ркОбщегоНазначенияСервер.ПолучитьДатуНачалаТекущегоРасчетногоПериода());
		ОшибкаПериода = Ложь;
		Если ДатаФормирования < ркОбщегоНазначенияСервер.ПолучитьДатуНачалаТекущегоРасчетногоПериода() Тогда
			ОшибкаПериода = Истина;
		КОнецЕсли;
		
		Документ.ТипОперации=Перечисления.ркТипыОперацийОплаты.ЗачетОплаты;
		Документ.ОтложенноеРаспределение = Истина;
		Документ.СпособОплаты = СпособОплаты;
		
		ДокументУстановитьСсылкуНового(Документ);
		
		Для Каждого СтрокаДанныхРеестра Из ДанныеДляЗагрузкиОплаты Цикл
			ДанныеДляОплаты = СтрокаДанныхРеестра.СтрокаРеестра;
			
			КодЛицевогоСчета = СокрЛП(ДанныеДляОплаты[Глоб_ИндексНомерЛС - 1]);
			ЛицевойСчет = Справочники.ркЛицевыеСчета.НайтиПоКоду(КодЛицевогоСчета);
			
			Если ЛицевойСчет.Ссылка.Пустая() Тогда
				ЗарегистрироватьОшибку(
					КодЛицевогоСчета,
					"Лицевой счет №"+КодЛицевогоСчета+" "+ДанныеДляОплаты[Глоб_ИндексФИО - 1]+" не найден!",
					ИмяРеестра,
					Документ.ПолучитьСсылкуНового(),
					"Оплата не загружена"
				);
				Продолжить;
			Иначе 
				СтрокаДокумента = Документ.Состав.Добавить();
				СтрокаДокумента.ЛицевойСчет = ЛицевойСчет; 
				СтрокаДокумента.Сумма = Число(ДанныеДляОплаты[Глоб_ИндексСуммаОплаты - 1])/100;
				ихВидУслуги = Лев(ДанныеДляОплаты[9],2);
				Если (ихВидУслуги="03")	тогда ихВидУслуги="000000001" конецесли;
				Если (ихВидУслуги="50")	тогда ихВидУслуги="000000006" конецесли;
				Если (ихВидУслуги="22")	тогда ихВидУслуги="000000007" конецесли;
				Если (ихВидУслуги="12")	тогда ихВидУслуги="000000016" конецесли;
				Если (ихВидУслуги="43")	тогда ихВидУслуги="000000017" конецесли;
				Если (ихВидУслуги="05")	тогда ихВидУслуги="000000010" конецесли;
				Если (ихВидУслуги="48")	тогда ихВидУслуги="000000011" конецесли;
				НашВидРасчета = Справочники.ркВидыРасчетов.НайтиПоКоду(ихВидУслуги);
				Если НЕ ЛицевойСчет.Ссылка.Пустая() Тогда
					СтрокаДокумента.ВидРасчета = НашВидРасчета;
					Иначе Сообщить("не нашел услугу "+ДанныеДляОплаты[9]);

					КонецЕсли;	
				СтрокаДокумента.ПравилаРаспределенияОплаты = Справочники.ркПравилаРаспределенияОплаты.НайтиПоКоду("000000001");	
				СтрокаДокумента.ДатаОплаты = ФорматироватьДату(ДанныеДляОплаты[Глоб_ИндексДатаОплаты - 1],ложь);
				//Сообщить(ДанныеДляОплаты[Глоб_ИндексДатаОплаты - 7]);
				КоличествоЗагруженныхОплат = КоличествоЗагруженныхОплат + 1;
			КонецЕсли;
		КонецЦикла;
		Если Документ.Состав.Количество() <> 0 И ОшибкаПериода = Ложь Тогда
			//Документ.ВыполнитьРаспределениеНаСервере();
			Документ.Записать(РежимЗаписиДокумента.Проведение);
			
			Сообщить("Создан документ:"+Документ.Ссылка);
		КонецЕсли;
		Если ОшибкаПериода Тогда
			Сообщить("Документ: "+Документ.Ссылка+" проведен в текущем периоде! Исходная дата документа: "+ДатаФормирования);
		КонецЕсли;
	КонецЕсли;		  
	Возврат КоличествоЗагруженныхОплат;
КонецФункции

Функция ЗагрузитьСчетчики(ИмяРеестра, ДатаФормирования, ИдентификаторРеестра, ДанныеДляЗагрузкиСчетчиков)
	
	КоличествоЗагруженныхСчетчиков = 0;
	
	Если ДанныеДляЗагрузкиСчетчиков.Количество() <> 0 Тогда
		
		ДокументПоказания = Новый Запрос("ВЫБРАТЬ ПЕРВЫЕ 1
			                                 |	ркПоказанияСчетчиков.Ссылка КАК ПоказанияСчетчиков
			                                 |ИЗ
			                                 |	Документ.ркПоказанияСчетчиков КАК ркПоказанияСчетчиков
			                                 |ГДЕ
			                                 |	ркПоказанияСчетчиков.ИдентификаторРеестра = &ИдентификаторРеестра
			                                 |	И ркПоказанияСчетчиков.ПометкаУдаления = Ложь");
		ДокументПоказания.УстановитьПараметр("ИдентификаторРеестра", ИдентификаторРеестра);
		РезультатыЗапросаДокументПоказания = ДокументПоказания.Выполнить().Выбрать();
		
		Если РезультатыЗапросаДокументПоказания.Следующий() Тогда
			Сообщить("Показания счетчиков из реестра " + ИмяРеестра + ", уже были загружены в документ "+РезультатыЗапросаДокументПоказания.ПоказанияСчетчиков);
			// реестр уже загружен
		Иначе
					
			ДокументПоказаний = Документы.ркПоказанияСчетчиков.СоздатьДокумент();
			ДокументПоказаний.ИдентификаторРеестра = ИдентификаторРеестра;
			ДокументПоказаний.Заполнить(Неопределено);					
			//ДокументПоказаний.Дата = Макс(ТекущаяДата(), ркОбщегоНазначенияСервер.ПолучитьДатуНачалаТекущегоРасчетногоПериода());
			ДокументПоказаний.Дата = ДатаФормирования;
			ДокументПоказаний.Комментарий = "Данные загружены из реестра::" + ИмяРеестра;
			
			ДокументУстановитьСсылкуНового(ДокументПоказаний);
			                        
			Для Каждого СтрокаДанныхРеестра Из ДанныеДляЗагрузкиСчетчиков Цикл
				
				//СчетчикиЛицевогоСчетаИзРеестра = ПолучитьСчетчикиИзСтрокиФайла(СтрокаДанныхРеестра.СтрокаРеестра, Глоб_ПозицияБлокаСчетчиков - 1);
				СчетчикиЛицевогоСчетаИзРеестра = 0;
				
				Если СчетчикиЛицевогоСчетаИзРеестра = 0 Тогда 
					Продолжить;
				КонецЕсли;
				
				Если СчетчикиЛицевогоСчетаИзРеестра = Неопределено Тогда
					ЗарегистрироватьОшибку(
						СтрокаДанныхРеестра.СтрокаРеестра[Глоб_ИндексНомерЛС - 1],
						"Ошибка формата строки счетчиков в лицевом счёте: " + СтрокаДанныхРеестра.СтрокаРеестра[Глоб_ИндексФИО - 1],
						ИмяРеестра,
						ДокументПоказаний.ПолучитьСсылкуНового(),
						"Счетчики не загружены"
					);
					Продолжить;
				КонецЕсли;
				
				ПредыдущийКодЛицевогоСчета = "";
				
				Для Каждого СчетчикЛС Из СчетчикиЛицевогоСчетаИзРеестра Цикл
										
					КодЛицевогоСчета = СчетчикЛС.КодЛС;
					
					ЛицевойСчет = Справочники.ркЛицевыеСчета.НайтиПоКоду(СчетчикЛС.КодЛС);
					
					Если ПредыдущийКодЛицевогоСчета <> КодЛицевогоСчета Тогда  
						СчетчикиЛицевогоСчетаИзБазы = ПолучитьСчетчикиЛицевогоСчетаИзБазы(ЛицевойСчет);
						ПредыдущийКодЛицевогоСчета = КодЛицевогоСчета;
					КонецЕсли;
					
					СчетчикЛицевогоСчетаВБазе = СчетчикиЛицевогоСчетаИзБазы.Найти(ВРег(СчетчикЛС.НаименованиеСчетчика), "СчетчикНаименование");
					
					Если СчетчикЛицевогоСчетаВБазе <> Неопределено Тогда
																
						Счетчик = СчетчикЛицевогоСчетаВБазе.СчетчикСсылка;
						ВидПоказаний = Справочники.ркВидыПоказанийСчетчиков.НайтиПоКоду(СчетчикЛС.КодВидаПоказания);
						НачальныеПоказания = Документы.ркПоказанияСчетчиков.ПолучитьНачальныеПоказанияПоПриборуУчета(Счетчик, ВидПоказаний);
						КонечныеПоказания = Документы.ркПоказанияСчетчиков.ФорматироватьПоказанияСУчетомРазрядности(Счетчик, ВидПоказаний, СчетчикЛС.Показания);
						Количество =  Число(КонечныеПоказания) - Число(НачальныеПоказания);
						
						Если Число(КонечныеПоказания) = 0 Тогда
							ЗарегистрироватьОшибку(
								СчетчикЛС.КодЛС,
								"Плательщик "+СчетчикЛС.ЛицевойСчет+" не подал показания счетчика '"+СчетчикЛС.НаименованиеСчетчика+"'",
								ИмяРеестра,
								ДокументПоказаний.ПолучитьСсылкуНового(),
								"Счетчик не загружен"
							);
							Продолжить;	
						КонецЕсли;
						Если Количество < 0 Тогда
							ЗарегистрироватьОшибку(
								СчетчикЛС.КодЛС,
								"Счетчик '"+СчетчикЛС.НаименованиеСчетчика+"' не заргужен из-за некорректных показаний",
								ИмяРеестра,
								ДокументПоказаний.ПолучитьСсылкуНового(),
								"Счетчик не загружен"
							);
							Продолжить;						
						КонецЕсли;
						
						СтрокаДокумента = ДокументПоказаний.Состав.Добавить();
						СтрокаДокумента.ЛицевойСчет = ЛицевойСчет;
						СтрокаДокумента.Дом = ЛицевойСчет.Дом;
						СтрокаДокумента.Помещение = ЛицевойСчет.Помещение;
						СтрокаДокумента.Счетчик = Счетчик; 
						СтрокаДокумента.ВидПоказаний = ВидПоказаний;
						СтрокаДокумента.НачальныеПоказания = НачальныеПоказания;
						СтрокаДокумента.КонечныеПоказания = КонечныеПоказания;
						СтрокаДокумента.Количество = Количество;
						СтрокаДокумента.ДатаНачалаПоказаний = ПолучитьДатуНачалаПоказаний(Счетчик, ВидПоказаний, ДатаФормирования);
						СтрокаДокумента.ДатаОкончанияПоказаний = КонецМесяца(ДатаФормирования);
						КоличествоЗагруженныхСчетчиков = КоличествоЗагруженныхСчетчиков + 1;
						
					Иначе 
						ЗарегистрироватьОшибку(
							СчетчикЛС.КодЛС,
							"Счетчик '"+СчетчикЛС.НаименованиеСчетчика+"' отсутствует",
							ИмяРеестра,
							ДокументПоказаний.ПолучитьСсылкуНового(),
							"Счетчик не загружен"
						);
					КонецЕсли;
				КонецЦикла;
			КонецЦикла;
			Если ДокументПоказаний.Состав.Количество() <> 0 Тогда 
				Документы.ркПоказанияСчетчиков.ВыполнитьРаспределениеПоказанийСчетчиков(ДокументПоказаний);
				ДокументПоказаний.Записать(РежимЗаписиДокумента.Проведение);
				Сообщить("Создан документ: "+ДокументПоказаний.Ссылка);
			КонецЕсли;
		КонецЕсли;
	Иначе
		КоличествоЗагруженныхСчетчиков = 0;
	КонецЕсли;	
	Возврат КоличествоЗагруженныхСчетчиков;
КонецФункции

Функция ПолучитьСчетчикиИзСтрокиФайла(МассивИзСтрокиРеестра, ПозицияБлокаСчетчиков,  РазделительОбщий = Истина)
	
	Счетчики = Новый Массив;
	
	Если РазделительОбщий Тогда 
		Для i = ПозицияБлокаСчетчиков по МассивИзСтрокиРеестра.Количество()-1 Цикл
			Счетчики.Добавить(МассивИзСтрокиРеестра[i]);
		КонецЦикла;		
	Иначе
		Счетчики = СтрРазделить(МассивИзСтрокиРеестра[ПозицияБлокаСчетчиков], Глоб_РазделительСчетчиков);
	КонецЕсли;
	
	ЗаменитьПустыеЭлементы(Счетчики);
		
	Если Счетчики.Количество() % 2 = 0 Тогда
		ТЗ = Новый ТаблицаЗначений;
		ТЗ.Колонки.Добавить("КодЛС");
		ТЗ.Колонки.Добавить("ЛицевойСчет");
		ТЗ.Колонки.Добавить("НаименованиеСчетчика");
		ТЗ.Колонки.Добавить("КодВидаПоказания");
		ТЗ.Колонки.Добавить("Показания");
		
		Позиция = 0;
		ДлинаКодаВидаПоказания = Метаданные.Справочники.ркВидыПоказанийСчетчиков.ДлинаКода;
		
		Пока Позиция < Счетчики.Количество() Цикл 
			СтрТЗ = ТЗ.Добавить();
			СтрТЗ.КодЛС = МассивИзСтрокиРеестра[Глоб_ИндексНомерЛС - 1];
			СтрТЗ.ЛицевойСчет = МассивИзСтрокиРеестра[Глоб_ИндексФИО - 1];
			СтрТЗ.НаименованиеСчетчика = СтрРазделить(Счетчики[Позиция], Глоб_РазделительКодовВНаименованииСчетчика)[1];
			СтрТЗ.КодВидаПоказания =  ДополнитьКодВедущимиНулями(СтрРазделить(Счетчики[Позиция], Глоб_РазделительКодовВНаименованииСчетчика)[0], ДлинаКодаВидаПоказания);
			СтрТЗ.Показания = Число(Счетчики[Позиция + 1]);
			Позиция = Позиция + 2;		
		КонецЦикла;
		Если ТЗ.Количество() > 0 Тогда
			Возврат ТЗ;
		Иначе
			Возврат 0;	
		КонецЕсли;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	
КонецФункции

Функция ПолучитьСчетчикиЛицевогоСчетаИзБазы(ЛицевойСчет)
	
	Запрос = Новый Запрос("ВЫБРАТЬ
	|	ркСчетчики.Код,
	|	ркСчетчики.Ссылка КАК СчетчикСсылка,
	|	ркСчетчики.Наименование КАК СчетчикНаименование
	|ИЗ
	|	Справочник.ркСчетчики КАК ркСчетчики
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.ркЛицевыеСчета КАК ркЛицевыеСчета
	|		ПО ркСчетчики.Владелец = ркЛицевыеСчета.Помещение
	|ГДЕ
	|	ркЛицевыеСчета.Ссылка = &ЛицевойСчет");
	
	Запрос.УстановитьПараметр("ЛицевойСчет", ЛицевойСчет);
	ТЗСчетчики = Запрос.Выполнить().Выгрузить();             
		
	Для Каждого Строка Из ТЗСчетчики Цикл
		Строка.СчетчикНаименование = ВРег(Строка.СчетчикНаименование);
	КонецЦикла;
	
	ТЗСчетчики.Индексы.Добавить("СчетчикНаименование");
	
	Возврат ТЗСчетчики;
	
КонецФункции

функция ДополнитьКодВедущимиНулями(ДополняемыйКод, ДлинаКодаВСправочнике)
	
	КоличествоДополняющихНулей = ДлинаКодаВСправочнике - СтрДлина(ДополняемыйКод);
	СтрокаДополняющихНулей = "";
	Для i = 1 По КоличествоДополняющихНулей Цикл 
		СтрокаДополняющихНулей = СтрокаДополняющихНулей + "0";
	КонецЦикла;
	
	Возврат Строка(СтрокаДополняющихНулей) + Строка(ДополняемыйКод);
	
КонецФункции

Функция ПолучитьВидПоказанийСчетчика(КодСчетчика)
	СписокВидовПоказаний = Справочники.ркСчетчики.НайтиПоКоду(КодСчетчика).ВидыПоказаний;
	КоличествоВидовПоказаний = СписокВидовПоказаний.Количество();
	ВидПоказаний = ?(КоличествоВидовПоказаний = 1, СписокВидовПоказаний[0].ВидПоказаний, Неопределено);
	Возврат ВидПоказаний;
КонецФункции

Функция ПолучитьДатуНачалаПоказаний(Счетчик, ВидПоказаний, Период)
	
	ДатаПоследнихПоказаний = Документы.ркПоказанияСчетчиков.ПолучитьДатуПоследнихПоказаний(Счетчик, ВидПоказаний, Период);
	ДатаОткрытияСчетчика = Документы.ркПоказанияСчетчиков.ПолучитьДатуОткрытияСчетчика(Счетчик, Период);
	//ДатаНачалаТекущегоРасчетногоПериода = ркОбщегоНазначенияСервер.ПолучитьДатуНачалаТекущегоРасчетногоПериода();
	ДатаФормирования = НачалоМесяца(Период);
	
	Если ДатаОткрытияСчетчика = Неопределено Тогда
		ПериодОткрытияСчетчика = Неопределено;
	Иначе
		ПериодОткрытияСчетчика = НачалоМесяца(ДатаОткрытияСчетчика);
	КонецЕсли;
	
	//Сравниваем какую дату использовать: ПериодОткрытияСчетчика или ДатаПоследнихПоказаний.
	Если ДатаПоследнихПоказаний = Неопределено Тогда
		ДатаНачалаПоказаний = ПериодОткрытияСчетчика;
	Иначе
		//Если в месяце были показания, то новые показания нужно вводить со следующего месяца
		ДатаНачалаПоказаний = НачалоМесяца(ДобавитьМесяц(ДатаПоследнихПоказаний, 1));
		Если ПериодОткрытияСчетчика <> Неопределено Тогда
			ДатаНачалаПоказаний = Макс(ДатаНачалаПоказаний, ПериодОткрытияСчетчика);
		КонецЕсли;
	КонецЕсли;
	
	//Сравниваем какую дату использовать: ДатаНачалаПоказаний или ДатаНачалаТекущегоРасчетногоПериода.
	Если ДатаНачалаПоказаний = Неопределено Тогда
		ДатаНачалаПоказаний = ДатаФормирования;
	Иначе
		ДатаНачалаПоказаний = Мин(ДатаНачалаПоказаний, ДатаФормирования);
	КонецЕсли;
	
	Возврат ДатаНачалаПоказаний;
КонецФункции

Процедура ДокументУстановитьСсылкуНового(Документ)
	НоваяСсылка = Документы[Документ.Метаданные().Имя].ПолучитьСсылку();
	Документ.УстановитьСсылкуНового(НоваяСсылка);
КонецПроцедуры

Процедура ЗарегистрироватьОшибку(НомерЛС, Описание, Реестр, Документ = Неопределено, ТипОшибки = "Ошибка")
	Строка = ЖурналОшибок.Добавить();
	Строка.Дата = ТекущаяДата();
	Строка.Реестр = Реестр;
	Строка.НомерЛС = НомерЛС;
	Строка.Описание = Описание;
	Строка.Документ = Документ;
	Строка.ТипОшибки = ТипОшибки;
КонецПроцедуры

Функция ПолучитьОтчетЖурналОшибок()
	ВнешниеДанные = Новый Структура("ЖурналОшибок", РеквизитФормыВЗначение("ЖурналОшибок"));
	Отчет = ПолучитьОтчетСКД("СКДЖурналОшибок", ВнешниеДанные);
	Возврат Отчет;
КонецФункции

Функция ПолучитьОтчетСКД(НаименованиеМакета, ВнешниеДанные)
	//Получаем схему из макета
	СхемаКомпоновкиДанных = РеквизитФормыВЗначение("Объект").ПолучитьМакет(НаименованиеМакета);
	
	//Из схемы возьмем настройки по умолчанию
	Настройки = СхемаКомпоновкиДанных.НастройкиПоУмолчанию;

	//Помещаем в переменную данные о расшифровке данных
	//ДанныеРасшифровки = Новый ДанныеРасшифровкиКомпоновкиДанных;

	//Формируем макет, с помощью компоновщика макета
	КомпоновщикМакета = Новый КомпоновщикМакетаКомпоновкиДанных;

	//Передаем в макет компоновки схему, настройки и данные расшифровки
	МакетКомпоновки = КомпоновщикМакета.Выполнить(СхемаКомпоновкиДанных, Настройки);
	
	//Выполним компоновку с помощью процессора компоновки
	ПроцессорКомпоновкиДанных = Новый ПроцессорКомпоновкиДанных;
	ПроцессорКомпоновкиДанных.Инициализировать(МакетКомпоновки, ВнешниеДанные);

	////Очищаем поле табличного документа
	//Результат = ЭлементыФормы.Результат;
	//Результат.Очистить();
	Результат = Новый ТабличныйДокумент();

	//Выводим результат в табличный документ
	ПроцессорВывода = Новый ПроцессорВыводаРезультатаКомпоновкиДанныхВТабличныйДокумент;
	ПроцессорВывода.УстановитьДокумент(Результат);

	ПроцессорВывода.Вывести(ПроцессорКомпоновкиДанных);
	
	Возврат Результат;
КонецФункции

Процедура СохранитьЛицевойСчетРРКЦ(НомерЛицевогоСчета, НомерЛицевогоСчетаРРКЦ)
	
	ЛицевойСчет = Справочники.ркЛицевыеСчета.НайтиПоКоду(НомерЛицевогоСчета);
	
	Если ЛицевойСчет <> Справочники.ркЛицевыеСчета.ПустаяСсылка() И НЕ ЛицевойСчет.ЭтоГруппа Тогда
		Если  ЛицевойСчет.ДатаЗакрытия = Дата(1,1,1) Тогда
			
			ЛицевойСчетОбъект = ЛицевойСчет.ПолучитьОбъект();
			
			ЛСБанка = "0";

			Попытка
				ДопРеквизитСвойство = ПланыВидовХарактеристик.ДополнительныеРеквизитыИСведения.НайтиПоНаименованию("Номер РРКЦ", Истина);
				ЕстьСтроки = ЛицевойСчет.ДополнительныеРеквизиты.НайтиСтроки(Новый Структура("Свойство", ДопРеквизитСвойство));
			
	       		Для каждого найдСтрока Из ЕстьСтроки Цикл
				ЛСБанка =  Строка(найдСтрока.Значение);
				КонецЦикла;	
			Исключение
			КонецПопытки;

			
			
				Если ЛСБанка <> НомерЛицевогоСчетаРРКЦ Тогда
					//ЛицевойСчетОбъект.НомерЖКУКапремонт = НомерЛицевогоСчетаРРКЦ;
				Сообщить(НомерЛицевогоСчета+"/"+НомерЛицевогоСчетаРРКЦ);	
				

				МассивСтруктур = Новый Массив;
				МассивСтруктур.Добавить(Новый Структура("Свойство, Значение", ДопРеквизитСвойство, НомерЛицевогоСчетаРРКЦ));
				УправлениеСвойствами.ЗаписатьСвойстваУОбъекта(ЛицевойСчет, МассивСтруктур);	
				
				Иначе 
					//ЛицевойСчетОбъект.НомерЖКУ = НомерЛицевогоСчетаРРКЦ;
				КонецЕсли;
				
			
//			ЛицевойСчетОбъект.Записать();
			
		КонецЕсли;
	Иначе
		Сообщить("Ошибка.  ЛицСчет "+НомерЛицевогоСчета+", не найден в программе!");
	КонецЕсли;
	
КонецПроцедуры


&НаКлиенте
Процедура ЗагрузитьПривязки(Команда)
	         //Открываем диалог выбора файла для чтения
        ВыборФайла= Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
        ВыборФайла.МножественныйВыбор = Ложь;
        ВыборФайла.Заголовок =НСтр("ru = ‘Выбор файла'");
        ВыборФайла.Фильтр=НСтр("ru = ‘Все файлы (*.rkp)|*.rkp'");
  
        Если ВыборФайла.Выбрать() Тогда
                ПолноеИмяФайла=ВыборФайла.ПолноеИмяФайла;
        Иначе Возврат;
        КонецЕсли;

	Ошибок=0;
	
	ТТХ1 = Новый ЧтениеТекста(ПолноеИмяФайла, КодировкаТекста.ANSI);
	ТекСтрока = "";
	
	Пока ТекСтрока <> Неопределено  Цикл 
		ТекСтрока = ТТХ1.ПрочитатьСтроку();

		Если Лев(ТекСтрока, 3) <>"100" Тогда	
			Продолжить;
		КонецЕсли;
		
		МассивПолей1 = СтрРазделить(ТекСтрока,"=");
		ИХ_ЛС= МассивПолей1[0];
		НАШ_ЛС= МассивПолей1[1];
		//ИХ_ЛС=СокрЛП(ИХ_ЛС);
		//ИХ_ЛС=Строка(Число(ИХ_ЛС));
		//Сообщить(НАШ_ЛС+"/"+ИХ_ЛС);
		//сообщить(ТекСтрока);
		СохранитьЛицевойСчетРРКЦ(НАШ_ЛС, ИХ_ЛС)
		


		
	КонецЦикла;
	
	Предупреждение("закончил");
	
КонецПроцедуры

#КонецОбласти

#Область ИнициализацияГлобальныхПеременных

	Глоб_ИндексНомерЛС = 4;
	Глоб_ИндексФИО = 5;
	Глоб_ИндексСуммаОплаты = 19;
	Глоб_ИндексДатаОплаты = 16;
	Глоб_ПозицияБлокаСчетчиков = 11;
	Глоб_РазделительПути = ПолучитьРазделительПути();
	Глоб_РазделительПолей = "|";
	Глоб_РазделительСчетчиков = ";";
	Глоб_РазделительКодовВНаименованииСчетчика = "#";
	
#КонецОбласти





