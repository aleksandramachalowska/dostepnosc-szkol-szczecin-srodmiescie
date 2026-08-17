# Analiza dostępności pieszej szkół w Śródmieściu Szczecina

## Opis projektu

Projekt dotyczy analizy sieciowej czasu dojścia pieszo do szkół w dzielnicy Śródmieście Szczecina. Wykorzystano do jego utworzenia oprogramowanie QGIS, PostgreSQL wraz z nakładką PostGIS oraz pgRouting. Zakres prac obejmował obróbkę danych, przygotowanie na ich podstawie grafu czasu oraz utworzenie izochron. Ważnym elementem było utworzenie grafu czasu z kosztem przejścia wyrażonym w sekundach. Dla większości dróg przyjęto prędkość poruszania 5 km/h, jednak dla ścieżek było to 4,5 km/h, a dla schodów które zwykle pokonuje się wolniej 2,5 km/h. Dalej odnaleziono najbliższe każdej szkole węzły grafu, z których dzięki algorytmowi Dijkstra obliczono dokąd można przejść po sieci w ustalonym czasie 5, 10 i 15 minut. Wynikiem analizy była mapa zawierająca rozmieszczenie izochron.

## Wykorzystane technologie

- PostgreSQL
- PostGIS
- pgRouting
- QGIS

## Dane

W projekcie wykorzystano dane:
- OpenStreetMap (lokalizacja sieci dróg, szkół),
- Geoportal Szczecina (granice Śródmieścia).

## Zakres prac

Prace obejmowały:
- import danych przestrzennych do bazy PostgreSQL,
- transformację układów współrzędnych warstw do jednolitego układu EPSG:2176,
- wyodrębnienie szkół i przycięcie ich do granicy Śródmieścia,
- wyselekcjonowanie dróg, które można pokonać pieszo, z warstw planet_osm_roads i planet_osm_line,
- przycięcie ich do granicy dzielnicy powiększonej o odpowiedni bufor pozwalający zachować drogi biegnące w pobliżu granicy,
- połączenie warstw dróg,
- utworzenie węzłów w miejscach przecięcia sieci,
- utworzenie dwukierunkowego grafu,
- stworzenie grafu uwzględniającego czas pokonania drogi w zależności od jej typu,
- znalezienie najbliższego węzła dla każdej szkoły i wszystkich węzłów dla szkół do których można dojść w założonym czasie,
- utworzenie izochron czasu dojścia w 5, 10 i 15 minut od szkół,
- wizualizacja wyników w QGIS oraz utworzenie mapy.

## Metodyka





## Ograniczenia

Należy uwzględnić, że dane OpenStreetMap mają charakter społecznościowy, co może wpływać na ich kompletność i aktualność.  
Dzielnica Śródmieście Szczecina obejmuje tereny leżące w ścisłym centrum miasta, jak również tereny wód, lasów i wysp, dla których dostępność szkół z powodu niezamieszkania nie jest istotna. Dlatego też mapa wynikowa skupia się na lewobrzeżnej części dzielnicy, zachowując mapę poglądową dla całości Śródmieścia.

## Autor

Aleksandra Machałowska
