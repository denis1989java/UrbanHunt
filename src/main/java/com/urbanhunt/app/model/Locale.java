package com.urbanhunt.app.model;

import com.google.cloud.firestore.annotation.DocumentId;
import com.google.cloud.spring.data.firestore.Document;

@Document(collectionName = "locales")
public class Locale {
    @DocumentId
    private String id;
    private String code;
    private String name;
    private String nativeName;

    public Locale() {
    }

    public Locale(String id, String code, String name, String nativeName) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.nativeName = nativeName;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getNativeName() {
        return nativeName;
    }

    public void setNativeName(String nativeName) {
        this.nativeName = nativeName;
    }
}
