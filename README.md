# boundedcamera
Basic custom camera for Godot 4.
Includes:
- Camera Area that will clamp the camera bounds
- Limits can be turned on or off for any of the rectangular sides and change priority
- Simple playable character that must have a child Area that will detect the Camera Area
- Simple world to move around
- Remote Camera that is a child of the world scene tree with logic to clamp and interpolate

Based on the logic from https://youtu.be/w4xM9EWKs3I
