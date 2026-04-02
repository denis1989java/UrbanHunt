package com.urbanhunt.app.controller;

import com.urbanhunt.app.model.Comment;
import com.urbanhunt.app.service.CommentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/challenges/{challengeId}/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping
    public ResponseEntity<Comment> createComment(
            @PathVariable String challengeId,
            @RequestBody Comment comment) {
        Comment created = commentService.createComment(challengeId, comment);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping
    public List<Comment> getComments(
            @PathVariable String challengeId,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String startAfter) {
        return commentService.getCommentsByChallengeId(challengeId, limit, startAfter);
    }

    @GetMapping("/count")
    public ResponseEntity<Long> getCommentsCount(@PathVariable String challengeId) {
        Long count = commentService.getCommentsCount(challengeId);
        return ResponseEntity.ok(count);
    }

    @DeleteMapping("/{commentId}")
    public ResponseEntity<Void> deleteComment(@PathVariable String commentId) {
        commentService.deleteComment(commentId);
        return ResponseEntity.noContent().build();
    }

}