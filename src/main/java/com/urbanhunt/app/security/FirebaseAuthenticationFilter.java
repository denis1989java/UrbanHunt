package com.urbanhunt.app.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Slf4j
@Component
@RequiredArgsConstructor
public class FirebaseAuthenticationFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String authorizationHeader = request.getHeader("Authorization");
        log.debug("Processing request: {} {}", request.getMethod(), request.getRequestURI());
        log.debug("Authorization header present: {}", authorizationHeader != null);

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            String token = authorizationHeader.substring(7);
            log.debug("Attempting to verify Firebase token");

            try {
                FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
                log.info("Firebase token verified successfully for user: {} ({})",
                         decodedToken.getEmail(), decodedToken.getUid());

                UserPrincipal userPrincipal = UserPrincipal.builder()
                        .uid(decodedToken.getUid())
                        .email(decodedToken.getEmail())
                        .name(decodedToken.getName())
                        .picture(decodedToken.getPicture())
                        .provider(getProvider(decodedToken))
                        .build();

                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                userPrincipal,
                                null,
                                Collections.emptyList()
                        );

                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
                log.debug("Authentication set in SecurityContext");

            } catch (FirebaseAuthException e) {
                log.error("Firebase token verification failed: {} - {}", e.getErrorCode(), e.getMessage());
                log.debug("Token verification error details", e);
            }
        } else {
            log.debug("No valid Authorization header found");
        }

        filterChain.doFilter(request, response);
    }

    private String getProvider(FirebaseToken token) {
        var firebase = token.getClaims().get("firebase");
        if (firebase instanceof java.util.Map) {
            var signInProvider = ((java.util.Map<?, ?>) firebase).get("sign_in_provider");
            return signInProvider != null ? signInProvider.toString() : "unknown";
        }
        return "unknown";
    }

}