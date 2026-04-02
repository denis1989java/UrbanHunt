package com.urbanhunt.app.controller;

import com.urbanhunt.app.model.Locale;
import com.urbanhunt.app.service.LocaleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/locales")
public class LocaleController {

    @Autowired
    private LocaleService localeService;

    @GetMapping
    public ResponseEntity<List<Locale>> getLocales() {
        List<Locale> locales = localeService.getAllLocales();
        return ResponseEntity.ok(locales);
    }
}
