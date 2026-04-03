package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.ConfirmPrizeRequest;
import com.urbanhunt.app.model.PrizeConfirmation;
import com.urbanhunt.app.security.SecurityUtils;
import com.urbanhunt.app.security.UserPrincipal;
import com.urbanhunt.app.service.PrizeConfirmationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/prize-confirmations")
@RequiredArgsConstructor
public class PrizeConfirmationController {

    private final PrizeConfirmationService prizeConfirmationService;

    @GetMapping("/{confirmationId}")
    public ResponseEntity<PrizeConfirmation> getConfirmationById(@PathVariable String confirmationId) {
        PrizeConfirmation confirmation = prizeConfirmationService.getConfirmationById(confirmationId);
        if (confirmation == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(confirmation);
    }

    @GetMapping("/challenge/{challengeId}")
    public ResponseEntity<PrizeConfirmation> getConfirmationByChallengeId(@PathVariable String challengeId) {
        PrizeConfirmation confirmation = prizeConfirmationService.getConfirmationByChallengeId(challengeId);
        if (confirmation == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(confirmation);
    }

    @PostMapping("/{confirmationId}/confirm")
    public ResponseEntity<PrizeConfirmation> confirmPrizeById(
            @PathVariable String confirmationId,
            @Valid @RequestBody ConfirmPrizeRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        try {
            PrizeConfirmation confirmation = prizeConfirmationService.confirmPrizeById(
                    confirmationId,
                    principal.getUid(),
                    request.getMessage(),
                    request.getContentUrl()
            );
            return ResponseEntity.ok(confirmation);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/challenge/{challengeId}/confirm")
    public ResponseEntity<PrizeConfirmation> confirmPrize(
            @PathVariable String challengeId,
            @Valid @RequestBody ConfirmPrizeRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        try {
            PrizeConfirmation confirmation = prizeConfirmationService.confirmPrize(
                    challengeId,
                    principal.getUid(),
                    request.getMessage(),
                    request.getContentUrl()
            );
            return ResponseEntity.ok(confirmation);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/user/me")
    public ResponseEntity<List<PrizeConfirmation>> getMyConfirmations() {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        List<PrizeConfirmation> confirmations = prizeConfirmationService.getConfirmationsByUserId(principal.getUid());
        return ResponseEntity.ok(confirmations);
    }
}