package com.urbanhunt.app.security;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final FirebaseAuthenticationFilter firebaseAuthenticationFilter;

    @Value("${app.security.disabled:false}")
    private boolean securityDisabled;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        if (securityDisabled) {
            // Local development: disable all security
            http.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
        } else {
            // Production: enforce security
            http.authorizeHttpRequests(auth -> auth
                            .requestMatchers("/api/health").permitAll()
                            .requestMatchers("/api/version/**").permitAll()
                            .requestMatchers(HttpMethod.GET, "/api/countries/**").permitAll()
                            .requestMatchers(HttpMethod.GET, "/api/locales/**").permitAll()
                            .requestMatchers(HttpMethod.GET, "/api/challenges/**").permitAll()
                            .requestMatchers(HttpMethod.GET, "/api/users/**").permitAll()
                            .requestMatchers("/api/auth/**").authenticated()
                            .requestMatchers(HttpMethod.POST, "/api/challenges/*/comments").authenticated()
                            .requestMatchers(HttpMethod.POST, "/api/challenges/*/complete").authenticated()
                            .requestMatchers(HttpMethod.POST, "/api/challenges/*/hints").authenticated()
                            .requestMatchers(HttpMethod.POST, "/api/challenges").authenticated()
                            .requestMatchers(HttpMethod.DELETE, "/**").authenticated()
                            .requestMatchers(HttpMethod.PATCH, "/**").authenticated()
                            .anyRequest().authenticated()
                    )
                    .addFilterBefore(firebaseAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        }

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

}