package com.urbanhunt.app.service;

import com.urbanhunt.app.model.Locale;
import com.urbanhunt.app.repository.LocaleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class LocaleService {

    @Autowired
    private LocaleRepository localeRepository;

    public List<Locale> getAllLocales() {
        return localeRepository.findAll()
                .collectList()
                .block();
    }
}