# ChatSDK

## Разработка

### Версии

Мы используем [SemVer](https://semver.org) и отмечаем влияние (impact) каждого изменения в файле `CHANGELOG.md` (это временное решение).

* MAJOR — любые изменения в API без обратной совместимости: если после изменения клиентский код перестает собираться, пока его не поправят, это всегда breaking change (независимо от продуктовой ценности фичи)
* MINOR — новый функционал (изменения в API) **с обратной совместимостью**: если клиенту не нужны новые функции, у него должна быть возможность перейти на новую версию без единого изменения
* PATCH — фиксы и доработки, **никак не изменяющие API**

⚠️ SemVer предполагает консервативный подход, поэтому **если impact не указан, изменение будет считаться MAJOR**.

⚠️ Версии 3.x.x используем для отладки процессов, поэтому MAJOR-изменения пока поднимают MINOR-версию (e.g. 3.2.2 → 3.3.0). На v4.0.0 перейдем в отдельный момент, когда хотя бы частично сделаем рефакторинг и стабилизируем процессы.

#### Примеры

1. В файле PATCH, MINOR, MAJOR = повышается MAJOR-версия, потому что имеется breaking change
1. В файле PATCH, MINOR, MINOR = повышается MINOR-версия, потому что имеются только new- и patch-изменения
1. В файле PATCH, <impact не указан>, MINOR = повышается MAJOR-версияб потому что у одного из изменений не указан impact

<hr>

<details>
<summary>README для v1.x–3.x</summary>

## Устройство проекта. Напутствие

Перед началом работы с чатом **морально приготовьтесь**. В проекте замысловатая архитектура, всё модульное и заменяемое, поэтому нельзя просто взять и быстро что-то пофиксить/допилить. Любая доработка это изнурительное прокидывание управления через слои архитектуры.

Визуально чат состоит из скроллящейся области с сообщениями (`Sources/Frontend/MessagesList`) и поля ввода нового сообщения (`Sources/Frontend/MessageInput`). Сообщения (`Message`) могут быть текстовыми, а также вложениями: изображение, видео, голос, контакт, геолокация, произвольный файл. Вложения выбираются с помощью `PickerModule`-й. Для отображения каждого типа сообщений используется соответствующий `ContentRenderer`.
Представление сообщений в виде вьюх выполнено замысловато. Дженерик на дженерике и вью-модель на вью-модели архитектурой погоняет. `MessagesList` реализован через `UICollectionView` с ячейками, параметризованными типами конкретных контент-вью. Еще один минус коллекции - для вычисления размеров ячеек используется ручная калькуляция высот, что иногда приводит к багам. Но в целом это не такой ад, как сетевая часть с отправкой, сохранением и черновиками.

Для отправки сообщений используются `ContentSender`-ы. Они же реализуют функциональнось `Attachment`-ов (прикрепленных вложений к неотправленному сообщению) и сериализацию/десериализацию в черновики. **Внимание:** если сообщение было отправлено, но не доставлено (зафейлилось при отстуствии интеренета, или все еще летит на сервер), то приложение считает его черновиком, то есть, в чате может быть более одного черновика. Черновики представлены типом `MessageDraft`. Это отдельная боль, сущность (и инфраструтура для ее обработки), размноженная без необходимости. Гораздо интуитивнее было бы представить черновики как не до конца заполненный `Message`. 

**Nota bene:** есть тонкость в наименованиях: на бэке чаты именуются как **channels**. Поэтому в сущностях и коде интеграции с бэком можно встретить поля типа `channelXXX`, например, `channelID`. Не пугайтесь, на практике "канал" это и есть чат. И еще разок: по логике сервера "чат" это мессенджер, приложение в целом, а уже каждый диалог в приложении - это "канал". Но в жизни так никто не говорит, поэтому в неймингах внутри ChatSDK слово `channel` старательно избегается.

ChatSDK использует веб-сокеты для получения уведомлений о новых сообщениях / появлении новых чатов. Реализовано бэком это довольно лениво - в сокет просто приходит айдишник "канала" в котором что-то произошло. Чат позволяет своим клиентам наблюдать за изменением сообщений в чате через класс `ChatBroadcastListener`. Бродкаст листенер вызывает клиентский `updateHandler` и передает туда превью измененного сообщения.

Из любопытного - чат поддерживает кастомизацию тем, стилей и шрифтов, логирование (замещенный метод `print`) и внешнее логирование (`acceptExternalLogger(_:)`).

Итак, если вы готовы погрузиться в мир ChatSDK, перейдите в `Sources/Common/Assembly.swift` и начните своё путешествие с изучения структуры компонентов, из которых он строится.


## Код стайл

[Стайлгайд проекта](https://hackmd.io/Z0L6qRdxQtm2898Fmc8StA). Линтер покрывает код самой СДК (директория `Source/`) при форматировании остального кода репозитория следует руководствоваться стайлгайдом и здравым смыслом.

## Правила работы в репозитории
Ветка `develop` – рабочая ветка, все фиче-ветки мерджим в нее.   
Ветки `feature/НАЗВАНИЕ_ЗАДАЧИ` и `fix/НАЗВАНИЕ_ЗАДАЧИ` – рабочие ветки для задач. Для удобства допускается читабельный суффикс:
`feature/CHATSDK-19_chatto_integration` вместо `feature/CHATSDK-19`.  

Все коммиты должны иметь в названии префикс с номером задачи: `CHATSDK-XX <Имя коммита>`. Все ветки мерджатся без squash, с мердж коммитом или фф.

## Используемые решения
В проект не затаскиваем сторонние библиотеки без крайней необходимости.  
Пример запрещенного – `Alamofire` (`URLSession` позволяет делать всё, что нужно в рамках чата), `RxSwift` (резко увеличивает порог вхождения), `SwiftyJSON` (есть `Codable`). 

В коде обильно используем замыкания (и не используем promises, futures и прочие средства асинхронности), поэтому рекомендуется быть внимательным при захвате нужного контекста (например, не захватывать сильную `self` для избежания release, если можно захватить конкретную часть контекста).

## Создание нового релиза
1. Обновить `ChatSDK.podspec`, проставить новую версию
2. Запушить в репозиторий
3. Создать новый тэг с версией: `git tag -a "1.0.0"`
4. Запушить тэг `git push --tags`

## Интеграция в другие приложения
1. Добавить в `Podfile` под с указанием ссылки на репозиторий и тэга-версии (можно вместо тега использовать хэш коммита или ветку – см. доки к cocoapods)
```
pod 'ChatSDK', :git => 'https://gitlab.technolab.com.ru/pr1me/chat_ios.git', :tag => '1.0.1'
``` 
2. Пример интеграции кода есть в исходниках `Sample` в этом репозитории
3. Дополнительно нужно добавить в `Info.plist` описание прав:
  - NSCameraUsageDescription
  - NSContactsUsageDescription
  - NSLocationAlwaysAndWhenInUseUsageDescription
  - NSLocationWhenInUseUsageDescription
  - NSMicrophoneUsageDescription
  - NSPhotoLibraryUsageDescription

</details>
