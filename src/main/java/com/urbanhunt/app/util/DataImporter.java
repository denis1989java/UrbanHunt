package com.urbanhunt.app.util;

import com.google.cloud.firestore.Firestore;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@Profile("import-data")
@RequiredArgsConstructor
public class DataImporter implements CommandLineRunner {

    private final Firestore firestore;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("🚀 Starting data import...");
        System.out.println("📍 Firestore project: " + firestore.getOptions().getProjectId());

        importSpainCities();
        importFranceCities();
        importGermanyCities();
        importLocales();
        importAppVersions();

        System.out.println("✅ Data import completed!");
        System.exit(0); // Exit after import
    }

    private void importSpainCities() throws Exception {
        List<String> cities = Arrays.asList(
                "Madrid",
                "Barcelona",
                "Valencia",
                "Seville",
                "Zaragoza",
                "Málaga",
                "Murcia",
                "Palma",
                "Las Palmas de Gran Canaria",
                "Bilbao",
                "Alicante",
                "Córdoba",
                "Valladolid",
                "Vigo",
                "Gijón",
                "L'Hospitalet de Llobregat",
                "Vitoria-Gasteiz",
                "A Coruña",
                "Elche",
                "Granada",
                "Terrassa",
                "Badalona",
                "Oviedo",
                "Cartagena",
                "Sabadell",
                "Jerez de la Frontera",
                "Móstoles",
                "Santa Cruz de Tenerife",
                "Pamplona"
        );

        Map<String, Object> countryData = new HashMap<>();
        countryData.put("name", "Spain");
        countryData.put("cities", cities);

        firestore.collection("countries").document("ES").set(countryData).get();

        System.out.println("✅ Imported Spain with " + cities.size() + " cities");
    }

    private void importFranceCities() throws Exception {
        List<String> cities = Arrays.asList(
                "Paris",
                "Marseille",
                "Lyon",
                "Toulouse",
                "Nice",
                "Nantes",
                "Strasbourg",
                "Montpellier",
                "Bordeaux",
                "Lille"
        );

        Map<String, Object> countryData = new HashMap<>();
        countryData.put("name", "France");
        countryData.put("cities", cities);

        firestore.collection("countries").document("FR").set(countryData).get();

        System.out.println("✅ Imported France with " + cities.size() + " cities");
    }

    private void importGermanyCities() throws Exception {
        List<String> cities = Arrays.asList(
                "Berlin",
                "Hamburg",
                "Munich",
                "Cologne",
                "Frankfurt",
                "Stuttgart",
                "Düsseldorf",
                "Dortmund",
                "Essen",
                "Leipzig"
        );

        Map<String, Object> countryData = new HashMap<>();
        countryData.put("name", "Germany");
        countryData.put("cities", cities);

        firestore.collection("countries").document("DE").set(countryData).get();

        System.out.println("✅ Imported Germany with " + cities.size() + " cities");
    }

    private void importLocales() throws Exception {
        System.out.println("🌍 Importing locales...");

        // English
        Map<String, Object> enLocale = new HashMap<>();
        enLocale.put("code", "en");
        enLocale.put("name", "English");
        enLocale.put("nativeName", "English");
        firestore.collection("locales").document("en").set(enLocale).get();

        // Spanish
        Map<String, Object> esLocale = new HashMap<>();
        esLocale.put("code", "es");
        esLocale.put("name", "Spanish");
        esLocale.put("nativeName", "Español");
        firestore.collection("locales").document("es").set(esLocale).get();

        System.out.println("✅ Imported 2 locales");
    }

    private void importAppVersions() throws Exception {
        System.out.println("📱 Importing app versions...");

        // iOS version configuration
        Map<String, Object> iosVersion = new HashMap<>();
        iosVersion.put("platform", "ios");
        iosVersion.put("minSupportedVersion", "1.0.0");
        iosVersion.put("latestVersion", "1.0.0");
        iosVersion.put("updateMessage", "Please update to the latest version to continue using UrbanHunt");
        iosVersion.put("forcedUpdate", false); // Change to true to force update

        firestore.collection("app_versions").document("ios").set(iosVersion).get();

        System.out.println("✅ Imported iOS app version config");

        // Android version configuration (for future)
        Map<String, Object> androidVersion = new HashMap<>();
        androidVersion.put("platform", "android");
        androidVersion.put("minSupportedVersion", "1.0.0");
        androidVersion.put("latestVersion", "1.0.0");
        androidVersion.put("updateMessage", "Please update to the latest version to continue using UrbanHunt");
        androidVersion.put("forcedUpdate", false);

        firestore.collection("app_versions").document("android").set(androidVersion).get();

        System.out.println("✅ Imported Android app version config");
    }
}