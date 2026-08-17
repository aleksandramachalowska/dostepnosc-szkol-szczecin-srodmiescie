# Analiza dostępności pieszej szkół w Śródmieściu Szczecina

## Opis projektu

Projekt dotyczy analizy sieciowej czasu dojścia pieszo do szkół w dzielnicy Śródmieście Szczecina. Wykorzystano do jego utworzenia oprogramowanie QGIS, PostgreSQL wraz z nakładką PostGIS oraz pgRouting. Zakres prac obejmował obróbkę danych, przygotowanie na ich podstawie grafu czasu oraz utworzenie izochron. Ważnym elementem było utworzenie grafu zawierającego węzły będące końcami krawędzi grafu oraz czasu ich przejścia obliczonego na podstawie założonej prędkości poruszania po drogach różnego typu. Dla większości dróg przyjęto prędkość 5 km/h, jednak dla ścieżek było to 4,5 km/h, a dla schodów które zwykle pokonuje się wolniej 2,5 km/h. Korzystając z tak utworzonego grafu odnaleziono jego najbliższe każdej szkole węzły, z których dzięki algorytmowi Dijkstra obliczono dokąd można przejść po sieci w ustalonym czasie 5, 10 i 15 minut. Dalsze prace pozwoliły na utworzenie izochron oraz mapy będącej wynikiem analizy.

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

W prac wykonano:
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

## Wnioski



## Mapa wynikowa

![Mapa dostępności szkol](szkoly.pdf)

## Ograniczenia danych

Należy uwzględnić, że dane OpenStreetMap mają charakter społecznościowy, co może wpływać na ich kompletność i aktualność. 

## Autor

Aleksandra Machałowska
