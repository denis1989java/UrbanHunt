package com.urbanhunt.app.service;

import com.urbanhunt.app.model.Comment;
import com.urbanhunt.app.repository.CommentRepository;
import com.urbanhunt.app.security.SecurityUtils;
import com.urbanhunt.app.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final ChallengeService challengeService;

    public Comment createComment(String challengeId, Comment comment) {
        UserPrincipal currentUser = SecurityUtils.getCurrentUser();
        if (currentUser != null) {
            comment.setAuthorId(currentUser.getUid());
            comment.setAuthorName(currentUser.getName());
        }

        comment.setChallengeId(challengeId);
        if (comment.getCreatedAt() == null) {
            comment.setCreatedAt(new Date());
        }

        Comment saved = commentRepository.save(comment);
        challengeService.incrementCommentsCount(challengeId);
        return saved;
    }

    public Comment getCommentById(String id) {
        return commentRepository.findById(id);
    }

    public List<Comment> getCommentsByChallengeId(String challengeId, int limit, String startAfter) {
        return commentRepository.findByChallengeId(challengeId, limit, startAfter);
    }

    public Long getCommentsCount(String challengeId) {
        return commentRepository.countByChallengeId(challengeId);
    }

    public void deleteComment(String id) {
        Comment comment = commentRepository.findById(id);
        if (comment != null) {
            commentRepository.deleteById(id);
            challengeService.decrementCommentsCount(comment.getChallengeId());
        }
    }

}