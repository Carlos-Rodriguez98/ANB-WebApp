package controllers

import (
	"ANB-WebApp/services/video-service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type VideoController struct{ Svc *services.VideoService }

func NewVideoController(s *services.VideoService) *VideoController { return &VideoController{Svc: s} }

// 3) POST /api/videos/upload  (multipart form-data: video_file, title)
func (ctl *VideoController) Upload(c *gin.Context) {
	userID := c.GetUint("user_id")
	title := c.PostForm("title")
	file, err := c.FormFile("video_file")
	if err != nil || title == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "title y video_file son requeridos"})
		return
	}
	res, err := ctl.Svc.Upload(userID, title, file)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, res)
}

// 4) GET /api/videos
func (ctl *VideoController) ListMine(c *gin.Context) {
	userID := c.GetUint("user_id")
	items, err := ctl.Svc.ListMine(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

// 5) GET /api/videos/{video_id}
func (ctl *VideoController) GetDetail(c *gin.Context) {
	userID := c.GetUint("user_id")
	id := c.Param("video_id")

	res, err := ctl.Svc.GetDetail(userID, id)
	if err != nil {
		switch err.Error() {
		case "not_found":
			c.JSON(http.StatusNotFound, gin.H{"error": "video no encontrado (no existe)"})
		case "forbidden":
			c.JSON(http.StatusForbidden, gin.H{"error": "no tienes permiso para acceder a este video"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error interno"})
		}
		return
	}

	c.JSON(http.StatusOK, res)
}

// 6) DELETE /api/videos/{video_id}
func (ctl *VideoController) Delete(c *gin.Context) {
	userID := c.GetUint("user_id")
	id := c.Param("video_id")

	err := ctl.Svc.Delete(userID, id)
	if err != nil {
		switch err.Error() {
		case "not_found":
			c.JSON(http.StatusNotFound, gin.H{"error": "video no encontrado (no existe)"})
		case "forbidden":
			c.JSON(http.StatusForbidden, gin.H{"error": "no tienes permiso para eliminar este video"})
		case "already_published":
			c.JSON(http.StatusBadRequest, gin.H{"error": "no se puede eliminar un video que ya esta publicado"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error interno del servidor"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "El video ha sido eliminado exitosamente.", "video_id": id})
}

// POST /api/videos/:video_id/publish
func (ctl *VideoController) Publish(c *gin.Context) {
	userID := c.GetUint("user_id")
	id := c.Param("video_id")

	if err := ctl.Svc.Publish(userID, id); err != nil {
		switch err.Error() {
		case "el video ya está publicado":
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		case "el video debe estar procesado para publicarse":
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		default:
			// incluye gorm.ErrRecordNotFound u otros
			c.JSON(http.StatusNotFound, gin.H{"error": "video no encontrado o no apto para publicar"})
		}
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "video publicado", "video_id": id})
}
