import bb.cascades 1.0
import FilePicker 1.0
import ImageEditor 1.0

Page {
    id: blurPage

    function openImage(image_file, gaussian_radius) {
        activityIndicator.visible = true;
        activityIndicator.start();

        blurEditor.radius = gaussian_radius;
        blurEditor.openImage(image_file);
    }

    paneProperties: NavigationPaneProperties {
        backButton: ActionItem {
            onTriggered: {
                navigationPane.pop();
            }
        }
    }

    actions: [
        ActionItem {
            id:                  undoActionItem
            title:               qsTr("Undo")
            imageSource:         "images/undo.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            enabled:             false

            onTriggered: {
                blurEditor.undo();
            }
        },
        ActionItem {
            id:                  saveActionItem
            title:               qsTr("Save")
            imageSource:         "images/save.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            enabled:             false

            onTriggered: {
                saveFilePicker.open();
            }
            
            attachedObjects: [
                FilePicker {
                    id:             saveFilePicker
                    type:           FileType.Picture
                    mode:           FilePickerMode.Saver
                    allowOverwrite: true
                    title:          qsTr("Save Image")
                    
                    onFileSelected: {
                        blurEditor.saveImage(selectedFiles[0]);
                    } 
                }
            ]
        },
        ActionItem {
            id:                  helpActionItem
            title:               qsTr("Help")
            imageSource:         "images/help.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                navigationPane.push(helpPageDefinition.createObject());
            }

            attachedObjects: [
                ComponentDefinition {
                    id:     helpPageDefinition
                    source: "HelpPage.qml"
                }
            ]
        }
    ]
    
    Container {
        id:         blurPageContainer
        background: Color.Black

        layout: StackLayout {
        }

        SegmentedControl {
            id:                  modeSegmentedControl
            horizontalAlignment: HorizontalAlignment.Center
            
            onSelectedValueChanged: {
                if (selectedValue === BlurEditor.ModeScroll) {
                    imageScrollView.touchPropagationMode = TouchPropagationMode.Full;
                } else {
                    imageScrollView.touchPropagationMode = TouchPropagationMode.PassThrough;
                }
                
                blurEditor.mode = selectedValue;
            }

            layoutProperties: StackLayoutProperties {
                spaceQuota: -1
            }

            Option {
                id:          scrollModeOption
                value:       BlurEditor.ModeScroll
                imageSource: "images/mode_scroll.png"
            }

            Option {
                id:          originalModeOption
                value:       BlurEditor.ModeOriginal
                imageSource: "images/mode_original.png"
                enabled:     false
            }

            Option {
                id:          effectedModeOption
                value:       BlurEditor.ModeEffected
                imageSource: "images/mode_effected.png"
                enabled:     false
            }
        }

        Container {
            id:                  imageContainer
            preferredWidth:      65535
            horizontalAlignment: HorizontalAlignment.Center 
            background:          Color.Transparent

            layoutProperties: StackLayoutProperties {
                spaceQuota: 1
            }

            layout: DockLayout {
            }

            function showHelper(touch_x, touch_y) {
                if (modeSegmentedControl.selectedValue !== BlurEditor.ModeScroll) {
                    helperImageView.visible = true;

                    var local_x = imageScrollViewLayoutUpdateHandler.layoutFrame.x + touch_x * imageScrollView.contentScale - imageScrollView.viewableArea.x;
                    var local_y = imageScrollViewLayoutUpdateHandler.layoutFrame.y + touch_y * imageScrollView.contentScale - imageScrollView.viewableArea.y;
    
                    if (local_y < helperImageViewLayoutUpdateHandler.layoutFrame.height * 2) {
                        if (local_x < helperImageViewLayoutUpdateHandler.layoutFrame.width * 2) {
                            helperImageView.horizontalAlignment = HorizontalAlignment.Right;
                        } else if (local_x > imageContainerLayoutUpdateHandler.layoutFrame.width - helperImageViewLayoutUpdateHandler.layoutFrame.width * 2) {
                            helperImageView.horizontalAlignment = HorizontalAlignment.Left;
                        }
                    }
                } else {
                    helperImageView.visible = false;
                }
            }

            ScrollView {
                id:                   imageScrollView
                horizontalAlignment:  HorizontalAlignment.Center
                verticalAlignment:    VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.Full
                
                scrollViewProperties {
                    scrollMode:         ScrollMode.Both
                    pinchToZoomEnabled: true
                    minContentScale:    1.0
                    maxContentScale:    4.0
                }            
                
                ImageView {
                    id:            imageView
                    scalingMethod: ScalingMethod.AspectFit 
                    
                    onTouch: {
                        if (event.touchType === TouchType.Down) {
                            imageContainer.showHelper(event.localX, event.localY);

                            blurEditor.changeImageAt(true, event.localX, event.localY, imageScrollView.contentScale);
                        } else if (event.touchType === TouchType.Move) {
                            imageContainer.showHelper(event.localX, event.localY);

                            blurEditor.changeImageAt(false, event.localX, event.localY, imageScrollView.contentScale);
                        } else {
                            helperImageView.visible = false;
                        }
                    }

                    attachedObjects: [
                        BlurEditor {
                            id:   blurEditor
                            mode: BlurEditor.ModeScroll 
                            
                            onImageOpened: {
                                activityIndicator.stop();
                                activityIndicator.visible = false;
                                
                                saveActionItem.enabled = true;
                                
                                modeSegmentedControl.selectedOption = scrollModeOption;
                                
                                originalModeOption.enabled = true;
                                effectedModeOption.enabled = true;
                                
                                imageScrollView.resetViewableArea(ScrollAnimation.Default);
                            }
                            
                            onImageOpenFailed: {
                                activityIndicator.stop();
                                activityIndicator.visible = false;
                                
                                saveActionItem.enabled = false;
                                
                                modeSegmentedControl.selectedOption = scrollModeOption;
                                
                                originalModeOption.enabled = false;
                                effectedModeOption.enabled = false;
                                
                                imageScrollView.resetViewableArea(ScrollAnimation.Default);
                                
                                MessageBox.showToast(qsTr("Could not open image"));
                            }
                            
                            onImageSaved: {
                                MessageBox.showToast(qsTr("Image saved successfully"));
                            }
                            
                            onImageSaveFailed: {
                                MessageBox.showToast(qsTr("Could not save image"));
                            }
                            
                            onUndoAvailabilityChanged: {
                                if (available) {
                                    undoActionItem.enabled = true;
                                } else {
                                    undoActionItem.enabled = false;
                                }
                            }
                            
                            onNeedImageRepaint: {
                                imageView.image = image;                            
                            }
                            
                            onNeedHelperRepaint: {
                                helperImageView.image = image;
                            }
                        }
                    ]
                }
                
                attachedObjects: [
                    LayoutUpdateHandler {
                        id: imageScrollViewLayoutUpdateHandler
                    }
                ]
            }
            
            ImageView {
                id:                  helperImageView
                horizontalAlignment: HorizontalAlignment.Left
                verticalAlignment:   VerticalAlignment.Top
                visible:             false
                
                attachedObjects: [
                    LayoutUpdateHandler {
                        id: helperImageViewLayoutUpdateHandler
                    }
                ]
            } 

            ActivityIndicator {
                id:                  activityIndicator
                preferredWidth:      256
                preferredHeight:     256
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment:   VerticalAlignment.Center
                visible:             false
            }

            attachedObjects: [
                LayoutUpdateHandler {
                    id: imageContainerLayoutUpdateHandler
                }
            ]
        }
    }
}