Логика.

Старт софта.

При старте софт ищет в реестре инфу.



Обработка нажатия кнопки «START»

1.	Выполняется первоначальная инициализация переменных с помощью процедуры SetGlobVar из модуля GlobVar.
2.	Проверяется выбор файла TLD*. Если он не выбран, выдвется соответствующее сообщение и активируется процесс выбора TLD файла.
3.	Загружаются в массивы данные из query и tld
4.	Формируется начальный список url согласно ТЗ ( к каждому url из  query добавляются окончания из tld)
5.	Создаются и запускаются потоки для парсина – по одному на каждый из сформированных url. При этом, если установлен предел потоков (options->multithread), софт ожидает, пока выполненное кол-во потоков не станет меньще, чем предел. Только после этоо запускаются очередные потоки.
6.	Софт ожидает окончания всех запущенных потоков.
7.	Специальный поток (в модуле Check Thread) обновляет текущую инфу о запущенных/выполненных/ошибочных потоках


ПОТОКИ (модуль WorkThread)
	При создании потока софт запрашивает результат. Если в результате есть ссылка на следующую страницу ( тэ <nextpage> ), то поток формирует следующую ссылку и создает новый поток. Естественно, если кол-во уже созданных потоков больше чем разрешенное кол-во, то поток ожидает, пока нельзя будет создать новый. 
	После создания дочернео потока, текущий поток парсит результат и «выдеривает» url, которые помещает в переменную DstResult, определенную внутри потока.
	После парсина поток в критической сессии (это такая хрень, в течении которой может работать только тот поток, который в нее вошел), записывает результаты парсина в соответствующий файл.
	Если по каким-либо причинам поток при запрос страницы с результатом получил ошибку (например, интернета нету), он ждет 15 секунд, после чео пытается получить страницу с результатом снова.
	Если все хорошо, и поток записал данные в файл, он завершается, удаляясь из памяти.
